import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'admin.dart';
import '../services/app_language.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  String? _customerPhone;
  bool _loading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    // Customer accounts use the backend session token, not Firebase.
    // Check the customer session first so a previous Firebase admin
    // session cannot make the customer profile show admin controls.
    final isCustomer = await _authService.isCustomerLoggedIn();

    if (isCustomer) {
      final phone = await _authService.getCustomerPhone();

      if (!mounted) return;

      setState(() {
        _customerPhone = phone;
        _isAdmin = false;
        _loading = false;
      });

      return;
    }

    // Only a Firebase user without a customer session can be an admin.
    final adminUser = _auth.currentUser;

    if (adminUser != null && !adminUser.isAnonymous) {
      try {
        final tokenResult = await adminUser.getIdTokenResult(true);
        final claims = tokenResult.claims;

        if (!mounted) return;

        setState(() {
          _isAdmin = claims?['admin'] == true;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;

        setState(() {
          _isAdmin = false;
          _loading = false;
        });
      }

      return;
    }

    if (!mounted) return;

    setState(() {
      _customerPhone = null;
      _isAdmin = false;
      _loading = false;
    });
  }

  Future<void> _logout() async {
    await _authService.logout();

    if (!mounted) return;

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _languageOption(
    BuildContext context,
    AppLanguage language,
    String label,
  ) {
    return ListTile(
      title: Text(label),
      trailing: ValueListenableBuilder<AppLanguage>(
        valueListenable: LanguageService.current,
        builder: (_, current, __) {
          return Icon(
            current == language
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
          );
        },
      ),
      onTap: () {
        LanguageService.setLanguage(language);
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),

          const Center(
            child: Icon(
              Icons.account_circle,
              size: 90,
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: ListTile(
              leading: const Icon(Icons.phone),
              title: const Text("Phone Number"),
              subtitle: Text(_customerPhone ?? user?.phoneNumber ?? "No phone number"),
            ),
          ),

          const SizedBox(height: 12),

          if (_loading)
            const Card(
              child: ListTile(
                leading: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
                title: Text("Checking account permissions..."),
              ),
            ),

          if (!_loading && _isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text("Admin Dashboard"),
                subtitle: const Text(
                  "Manage Items, payments and orders",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminPage(),
                    ),
                  );
                },
              ),
            ),

          if (!_loading && !_isAdmin)
            Card(
              child: ListTile(
                leading: const Icon(Icons.person),
                title: const Text("Customer Account"),
                subtitle: Text(
                  _customerPhone == null
                      ? "Customer account"
                      : "Signed in as $_customerPhone",
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text("Customer Account"),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Account status",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _customerPhone == null
                                  ? "Customer account"
                                  : "Signed in as $_customerPhone",
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Your customer account is active.",
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("CLOSE"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: const Text("Language"),
              subtitle: ValueListenableBuilder<AppLanguage>(
                valueListenable: LanguageService.current,
                builder: (_, language, __) {
                  return Text(LanguageService.languageName);
                },
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Choose Language"),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _languageOption(
                            context,
                            AppLanguage.english,
                            "English",
                          ),
                          _languageOption(
                            context,
                            AppLanguage.amharic,
                            "አማርኛ",
                          ),
                          _languageOption(
                            context,
                            AppLanguage.tigrinya,
                            "ትግርኛ",
                          ),
                          _languageOption(
                            context,
                            AppLanguage.oromo,
                            "Afaan Oromoo",
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text("Sign Out"),
            ),
          ),
        ],
      ),
    );
  }
}
