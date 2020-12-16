"""
BASICS

Email functionality
"""

from email import encoders
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.utils import parseaddr
import os
import smtplib




# Validates if an email address has the correct format
# email_addr(str)
# Returns True if yes, False for No
def correctly_formatted_email_address(email_addr):

    if parseaddr(email_addr) == ('', ''):
        return False
    else:
        return True



# Emails an user using the development queue, assumes a gmail account
# send_to (arr) (str): Email address of recipients
# text (str): Text to be sent, always constant
# attachments (arr) (str paths): Attachments to be included, defaults to empty

def send_mail_dev(send_to, subject, text, attachments):
    sender = os.environ['SENDER_EMAIL']
    password = os.environ['SENDER_EMAIL_PASSWORD']

    # Creates the actual message
    main_text = MIMEMultipart()
    main_text['Subject'] = subject
    main_text['To'] = send_to
    main_text['From'] = sender
    main_text.attach(MIMEText(text, 'plain'))

    # Add the attachments to the message
    for file in attachments:
        with open(file, 'rb') as fp:
             msg = MIMEBase('application', "octet-stream")
             msg.set_payload(fp.read())
        encoders.encode_base64(msg)
        msg.add_header('Content-Disposition', 'attachment', filename=os.path.basename(file))
        main_text.attach(msg)

    full_message = main_text.as_string()

    try:
        with smtplib.SMTP('smtp.gmail.com', 587) as s:
             s.starttls()
             s.login(sender, password)
             s.sendmail(sender, [send_to], full_message)
             s.close()
        return "Successfully email"
    except:
        return "ERROR sending email"



