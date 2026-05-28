import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistroPage extends StatelessWidget {
  final TextEditingController txtUsername = TextEditingController();
  final TextEditingController txtEmail = TextEditingController();
  final TextEditingController txtSenha = TextEditingController();

  RegistroPage({super.key});

  Future registrar(BuildContext context) async {
    try {
      var credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: txtEmail.text,
        password: txtSenha.text
      );

      await FirebaseFirestore.instance
        .collection('usuarios')        
        .doc(credential.user!.uid)     
        .set({
          'nome': txtUsername.text,
          'pontuacao': 0,              
          'email': txtEmail.text,
        });

      await credential.user?.updateDisplayName(txtUsername.text);

    txtUsername.clear();
    txtEmail.clear();
    txtSenha.clear();

    if (!context.mounted) return; // tela pode ter sido descartada durante o await
    Navigator.of(context).pushReplacementNamed('/home');

    } catch (erro) {
      if (!context.mounted) return; // mesma proteção para a SnackBar de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao fazer registro: ${erro.toString()}"),
          backgroundColor: const Color.fromARGB(255, 240, 104, 94),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(64, 61, 57, 1),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent, //COR
        title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("M.E.T.R.O", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Color.fromRGBO(253, 128, 46, 1.0))),
          Text("REGISTRO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromRGBO(253, 128, 46, 1.0)),
          ),
        ],
      ),
      ),

      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth = (constraints.maxWidth - 40).clamp(0.0, 420.0).toDouble();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      spacing: 12,
                      mainAxisSize: MainAxisSize.min,
                      children: [
            
                        TextField(
              controller: txtUsername,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    width: 2.5,
                  ),
                ),
                labelText: "Username",
                labelStyle: TextStyle(color: Color.fromRGBO(253, 128, 46, 1.0)),
                prefixIcon: Icon(Icons.person_outline),
                prefixIconColor: Color.fromRGBO(253, 128, 46, 1.0),
              ),
                        ), // TextField

                        TextField(
              controller: txtEmail,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    width: 2.5,
                  ),
                ),
                labelText: "E-mail",
                labelStyle: TextStyle(color: Color.fromRGBO(253, 128, 46, 1.0)),
                prefixIcon: Icon(Icons.email_outlined),
                prefixIconColor: Color.fromRGBO(253, 128, 46, 1.0),
              ),
                        ), // TextField

                        TextField(
              controller: txtSenha,
              obscureText: true,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    width: 2.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(253, 128, 46, 1.0),
                    width: 2.5,
                  ),
                ),
                labelText: "Senha",
                labelStyle: TextStyle(color: Color.fromRGBO(253, 128, 46, 1.0)),
                prefixIcon: Icon(Icons.lock_outline),
                prefixIconColor: Color.fromRGBO(253, 128, 46, 1.0),
              ),
                        ), // TextField

                        ElevatedButton(
              onPressed: () => registrar(context),
              child: Text("Registrar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(253, 128, 46, 1.0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
                        ),

                        TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Login"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromRGBO(253, 128, 46, 1.0),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
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
}
