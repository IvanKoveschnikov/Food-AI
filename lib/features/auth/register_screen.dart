import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:food_ai/core/constants/app_strings.dart';
import 'package:food_ai/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _acceptedTerms = false;
  String? _termsError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _termsError = null;
      _loading = true;
    });
    try {
      await signUp(
        email: _email.text.trim(),
        password: _password.text,
        displayName: _displayName.text.trim().isEmpty
            ? null
            : _displayName.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
    if (mounted && _loading) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;
            final maxFormWidth = width < 480 ? width - 48 : 480.0;
            final topPadding = height > 700 ? 48.0 : 24.0;
            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, topPadding, 24, 24),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxFormWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          AppStrings.register,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Начните свой путь к осознанному питанию с Food AI',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'Ваше имя',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _displayName,
                          decoration: const InputDecoration(
                            hintText: 'Иван Иванов',
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Электронная почта',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            hintText: 'example@mail.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Введите email' : null,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Пароль',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _password,
                          decoration: const InputDecoration(hintText: 'Пароль'),
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _onSubmitPressed(),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Введите пароль';
                            }
                            if (v.length < 6) {
                              return 'Пароль не менее 6 символов';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _acceptedTerms,
                              onChanged: _loading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _acceptedTerms = value ?? false;
                                        _termsError = null;
                                      });
                                    },
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Я согласен с условиями использования и политикой конфиденциальности',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[700]),
                              ),
                            ),
                          ],
                        ),
                        if (_termsError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _termsError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _loading ? null : _onSubmitPressed,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            shape: const StadiumBorder(),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Зарегистрироваться'),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Уже есть аккаунт? '),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : () => context.go('/login'),
                              child: const Text('Войти'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onSubmitPressed() {
    if (!_acceptedTerms) {
      setState(() {
        _termsError = 'Нужно согласиться с условиями использования';
      });
      return;
    }
    if (_formKey.currentState!.validate()) {
      _submit();
    }
  }
}
