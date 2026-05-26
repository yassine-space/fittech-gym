import json
from django.utils import timezone
from channels.generic.websocket import AsyncWebsocketConsumer
from channels.db import database_sync_to_async
from fitapi.models import Conversation, Message, User


class ChatConsumer(AsyncWebsocketConsumer):

    async def connect(self):
        self.conversation_id = self.scope["url_route"]["kwargs"]["conversation_id"]
        self.room_group_name = f"chat_{self.conversation_id}"
        self.user = self.scope["user"]

        # Reject unauthenticated users
        if not self.user or not self.user.is_authenticated:
            await self.close()
            return

        # Verify user belongs to this conversation
        allowed = await self.user_in_conversation(self.conversation_id, self.user)
        if not allowed:
            await self.close()
            return

        # Mark user as online
        await self.set_online_status(self.user, True)

        await self.channel_layer.group_add(self.room_group_name, self.channel_name)
        await self.accept()

        # Notify others that user is online
        await self.channel_layer.group_send(
            self.room_group_name,
            {"type": "user_status", "user_id": str(self.user.id), "online": True}
        )

    async def disconnect(self, close_code):
        await self.set_online_status(self.user, False)

        await self.channel_layer.group_send(
            self.room_group_name,
            {"type": "user_status", "user_id": str(self.user.id), "online": False}
        )

        await self.channel_layer.group_discard(self.room_group_name, self.channel_name)

    async def receive(self, text_data):
        data = json.loads(text_data)
        action = data.get("action")

        if action == "send_message":
            message = await self.save_message(data)
            await self.channel_layer.group_send(
                self.room_group_name,
                {
                    "type": "chat_message",
                    "message_id": str(message.id),
                    "sender_id": str(self.user.id),
                    "message_type": message.message_type,
                    "content": message.content,
                    "created_at": message.created_at.isoformat(),
                }
            )
        # Notify recipient only if offline
            await self.notify_recipient_if_offline(message)

        elif action == "mark_read":
            await self.mark_messages_read(self.conversation_id, self.user)
            await self.channel_layer.group_send(
                self.room_group_name,
                {"type": "messages_read", "user_id": str(self.user.id)}
            )

        elif action == "delete_message":
            message_id = data.get("message_id")
            deleted = await self.delete_message(message_id, self.user)
            if deleted:
                await self.channel_layer.group_send(
                    self.room_group_name,
                    {"type": "message_deleted", "message_id": message_id}
                )

    # ── Event handlers (group_send → WebSocket) ──

    async def chat_message(self, event):
        await self.send(text_data=json.dumps({
            "action": "new_message",
            "message_id": event["message_id"],
            "sender_id": event["sender_id"],
            "message_type": event["message_type"],
            "content": event["content"],
            "created_at": event["created_at"],
        }))

    async def messages_read(self, event):
        await self.send(text_data=json.dumps({
            "action": "messages_read",
            "user_id": event["user_id"],
        }))

    async def message_deleted(self, event):
        await self.send(text_data=json.dumps({
            "action": "message_deleted",
            "message_id": event["message_id"],
        }))

    async def user_status(self, event):
        await self.send(text_data=json.dumps({
            "action": "user_status",
            "user_id": event["user_id"],
            "online": event["online"],
        }))

    # ── DB helpers ──

    @database_sync_to_async
    def user_in_conversation(self, conversation_id, user):
        try:
            conversation = Conversation.objects.get(id=conversation_id)
            return (
                conversation.coach.user == user or
                conversation.membre.user == user
            )
        except Conversation.DoesNotExist:
            return False

    @database_sync_to_async
    def save_message(self, data):
        conversation = Conversation.objects.get(id=self.conversation_id)
        return Message.objects.create(
            conversation=conversation,
            sender=self.user,
            message_type=data.get("message_type", "text"),
            content=data.get("content", ""),
        )

    @database_sync_to_async
    def mark_messages_read(self, conversation_id, user):
        Message.objects.filter(
            conversation_id=conversation_id,
            is_read=False,
        ).exclude(sender=user).update(is_read=True)

    @database_sync_to_async
    def delete_message(self, message_id, user):
        try:
            message = Message.objects.get(id=message_id, sender=user)
            message.deleted_at = timezone.now()
            message.save()
            return True
        except Message.DoesNotExist:
            return False

    @database_sync_to_async
    def set_online_status(self, user, status):
        User.objects.filter(id=user.id).update(is_online=status)


    @database_sync_to_async
    def notify_recipient_if_offline(self, message):
        from .models import Notification
        conversation = Conversation.objects.select_related(
            "coach__user", "membre__user"
        ).get(id=self.conversation_id)

    # Determine recipient
        if conversation.coach.user == self.user:
            recipient = conversation.membre.user
        else:
            recipient = conversation.coach.user

    # Only notify if offline
        if not recipient.is_online:
            sender_name = f"{self.user.first_name} {self.user.last_name}"
            Notification.objects.create(
                user=recipient,
                notification_type="new_message",
                title=f"New message from {sender_name}",
                body=message.content if message.message_type == "text" else f"[{message.message_type}]",
            )