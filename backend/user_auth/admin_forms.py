from django import forms

class NotificationForm(forms.Form):
    message = forms.CharField(
        label="Notification Message",
        widget=forms.Textarea(attrs={'rows': 4, 'cols': 60}),
        max_length=500,
        required=True
    )
