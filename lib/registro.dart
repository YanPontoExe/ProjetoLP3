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

    Navigator.of(context).pushReplacementNamed('/game');
  
    } catch (erro) {
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
        backgroundColor: Color.fromRGBO(253, 128, 46, 1.0), //COR
        title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text("M.E.T.R.O", style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          Text("REGISTRO", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      ),

      body: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(64, 61, 57, 1), //COR
          ),
        margin: EdgeInsets.all(20),
        child: Column(
          spacing: 12,
          mainAxisAlignment: .center,
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
    );
  }
}
