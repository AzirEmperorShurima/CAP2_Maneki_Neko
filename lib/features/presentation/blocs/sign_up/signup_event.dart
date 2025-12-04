sealed class SignupEvent {}

class SignupSubmitted extends SignupEvent {
  final String name;
  final String email;
  final String password;
  SignupSubmitted({required this.name, required this.email, required this.password});
}


