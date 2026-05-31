import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _clubNameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _usnController = TextEditingController();
  final _branchController = TextEditingController();
  String _role = 'student';
  String _year = '1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Name is required.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Email is required.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                obscureText: true,
                validator: (value) => value == null || value.trim().isEmpty ? 'Password is required.' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'student', child: Text('Student')),
                DropdownMenuItem(value: 'coordinator', child: Text('Club Coordinator')),
              ],
              onChanged: (val) {
                setState(() {
                  _role = val!;
                });
              },
              decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
            ),
            if (_role == 'coordinator') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _clubNameController,
                decoration: const InputDecoration(labelText: 'Club Name', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Club name is required.' : null,
              ),
            ] else ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _year,
                items: const [
                  DropdownMenuItem(value: '1', child: Text('1st Year')),
                  DropdownMenuItem(value: '2', child: Text('2nd Year')),
                  DropdownMenuItem(value: '3', child: Text('3rd Year')),
                  DropdownMenuItem(value: '4', child: Text('4th Year')),
                  DropdownMenuItem(value: '5', child: Text('5th Year')),
                ],
                onChanged: (val) {
                  setState(() {
                    _year = val!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Year', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _departmentController, decoration: const InputDecoration(labelText: 'Department (e.g., CS, IT)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _usnController, decoration: const InputDecoration(labelText: 'USN (University Serial Number)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              TextFormField(controller: _branchController, decoration: const InputDecoration(labelText: 'Branch', border: OutlineInputBorder())),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) {
                  return;
                }
                
                final email = _emailController.text.trim();
                if (!email.toLowerCase().endsWith('@bmsce.ac.in')) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please use your @bmsce.ac.in email address to sign up.'))
                  );
                  return;
                }
                
                try {
                  await ref.read(authServiceProvider).signup(
                    email: email,
                    password: _passwordController.text.trim(),
                    name: _nameController.text.trim(),
                    role: _role,
                    clubName: _role == 'coordinator' ? _clubNameController.text.trim() : null,
                    year: _role == 'student' ? _year : null,
                    department: _role == 'student' ? _departmentController.text.trim() : null,
                    usn: _role == 'student' ? _usnController.text.trim() : null,
                    branch: _role == 'student' ? _branchController.text.trim() : null,
                  );
                } catch (e) {
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signup failed: ${e.toString()}')));
                   }
                }
              },
              child: const Text('Sign Up'),
            )
          ],
        ),
      ),
      ),
    );
  }
}
