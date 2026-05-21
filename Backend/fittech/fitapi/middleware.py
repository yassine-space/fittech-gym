import django
from urllib.parse import parse_qs
from channels.db import database_sync_to_async
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.tokens import AccessToken


def get_user_model():
    from fitapi.models import User
    return User


@database_sync_to_async
def get_user_from_token(token_string):
    try:
        User = get_user_model()
        token = AccessToken(token_string)
        return User.objects.get(id=token["user_id"])
    except Exception:
        return AnonymousUser()


class JWTAuthMiddleware:
    def __init__(self, inner):
        self.inner = inner

    async def __call__(self, scope, receive, send):
        query_string = scope.get("query_string", b"").decode()
        params = parse_qs(query_string)
        token_list = params.get("token", [None])
        token_string = token_list[0]

        if token_string:
            scope["user"] = await get_user_from_token(token_string)
        else:
            scope["user"] = AnonymousUser()

        return await self.inner(scope, receive, send)