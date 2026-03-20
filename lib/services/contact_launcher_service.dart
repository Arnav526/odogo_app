import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactLauncherService {
  static String _sanitizePhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  static Future<void> callNumber(BuildContext context, String? phone) async {
    final sanitized = _sanitizePhone(phone ?? '');
    if (sanitized.isEmpty) {
      _showMessage(context, 'Phone number not available.');
      return;
    }

    final uri = Uri(scheme: 'tel', path: sanitized);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showMessage(context, 'Could not open phone app.');
    }
  }

  static Future<void> smsNumber(BuildContext context, String? phone) async {
    final sanitized = _sanitizePhone(phone ?? '');
    if (sanitized.isEmpty) {
      _showMessage(context, 'Phone number not available.');
      return;
    }

    final uri = Uri(scheme: 'sms', path: sanitized);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      _showMessage(context, 'Could not open messages app.');
    }
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }
}
