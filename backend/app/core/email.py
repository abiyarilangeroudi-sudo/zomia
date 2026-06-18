import smtplib
import ssl
from email.message import EmailMessage
from email.utils import formataddr

import certifi
from fastapi import HTTPException, status

from app.core.config import Settings


class EmailSender:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    def send_email(self, *, to_email: str, subject: str, body: str) -> None:
        if self.settings.email_delivery_mode == "disabled":
            return
        if self.settings.email_delivery_mode != "smtp":
            return
        if (
            self.settings.smtp_host is None
            or self.settings.smtp_username is None
            or self.settings.smtp_password is None
            or self.settings.smtp_from_email is None
        ):
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Email delivery is not configured",
            )

        message = EmailMessage()
        message["Subject"] = subject
        message["From"] = formataddr((self.settings.smtp_from_name, self.settings.smtp_from_email))
        message["To"] = to_email
        message.set_content(body)

        with smtplib.SMTP(
            self.settings.smtp_host,
            self.settings.smtp_port,
            timeout=20,
        ) as server:
            server.ehlo()
            if self.settings.smtp_use_tls:
                server.starttls(context=ssl.create_default_context(cafile=certifi.where()))
                server.ehlo()
            server.login(self.settings.smtp_username, self.settings.smtp_password)
            server.send_message(message)
