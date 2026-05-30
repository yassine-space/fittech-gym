

from django.conf import settings
from chargily_pay import ChargilyClient
from chargily_pay.entity import Checkout

# Single shared client — instantiated once when Django loads
client = ChargilyClient(
    key=settings.CHARGILY_KEY,
    secret=settings.CHARGILY_SECRET,
    url=settings.CHARGILY_URL,
)


def build_checkout_entity(payment, chargily_checkout, success_url, failure_url, webhook_url):
    """
    Builds a Chargily Checkout entity from your Payment model instance.

    Important notes:
    - Amount must be an integer (DZD, no decimal places).
    - The description embeds the invoice_number for easy traceability.
    - pass_fees_to_customer=False means your gym absorbs Chargily's fees.
      Set to True if you want fees added on top for the user.
    """
    return Checkout(
        amount=int(payment.amount),
        currency="dzd",
        success_url=success_url,
        failure_url=failure_url,
        webhook_endpoint=webhook_url,
        payment_method=chargily_checkout.chargily_method,
        locale=chargily_checkout.locale,
        description=f"Abonnement FitTech - Facture #{payment.invoice_number}",
        pass_fees_to_customer=False,
    )