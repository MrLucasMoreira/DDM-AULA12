import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MaterialApp(debugShowCheckedModeBanner: false, home: MeuApp()));
}

class MeuApp extends StatefulWidget {
  const MeuApp({super.key});

  @override
  State<MeuApp> createState() => _MeuAppState();
}

class _MeuAppState extends State<MeuApp> with WidgetsBindingObserver {
  int fator = 1;
  int numero = 1;
  String resposta = '';
  bool carregando = true;

  final prefs = SharedPreferencesAsync();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    carregarProgresso();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      unawaited(salvarProgresso());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(salvarProgresso());
    super.dispose();
  }

  Future<void> carregarProgresso() async {
    int fatorSalvo = await prefs.getInt('fator') ?? 1;
    int numeroSalvo = await prefs.getInt('numero') ?? 1;

    if (!mounted) return;

    setState(() {
      fator = fatorSalvo;
      numero = numeroSalvo;
      carregando = false;
    });
  }

  Future<void> salvarProgresso() async {
    if (carregando) return;

    final fatorAtual = fator;
    final numeroAtual = numero;

    await prefs.setInt('fator', fatorAtual);
    await prefs.setInt('numero', numeroAtual);
  }

  void adicionarNumero(String valor) {
    setState(() {
      if (resposta.length < 6) {
        resposta += valor;
      }
    });
  }

  void apagarNumero() {
    if (resposta.isNotEmpty) {
      setState(() {
        resposta = resposta.substring(0, resposta.length - 1);
      });
    }
  }

  void limparResposta() {
    setState(() {
      resposta = '';
    });
  }

  Future<void> verificar() async {
    if (resposta.isEmpty) return;

    int? valor = int.tryParse(resposta);

    if (valor == fator * numero) {
      if (numero < 10) {
        setState(() {
          numero++;
        });
      } else {
        setState(() {
          fator++;
          numero = 1;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acertou todas! Próximo fator.')),
        );
      }
    } else {
      int fatorAnterior = fator;

      setState(() {
        fator++;
        numero = 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Errou, clique aqui para continuar'),
          duration: const Duration(seconds: 10),
          action: SnackBarAction(
            label: 'Continuar',
            onPressed: () async {
              setState(() {
                fator = fatorAnterior;
                numero = 1;
                resposta = '';
              });

              await salvarProgresso();
            },
          ),
        ),
      );
    }

    limparResposta();
    await salvarProgresso();
  }

  Widget botaoNumero(String texto, {VoidCallback? acao}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: ElevatedButton(
          onPressed: acao ?? () => adicionarNumero(texto),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: Colors.blue.shade50,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(texto, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progresso = (numero - 1) / 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tabuada'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Fator: $fator',
                        style: const TextStyle(fontSize: 24),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Progresso: ${(progresso * 100).toInt()}%',
                        style: const TextStyle(fontSize: 18),
                      ),

                      const SizedBox(height: 10),

                      LinearProgressIndicator(
                        value: progresso,
                        minHeight: 12,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        '$fator x $numero = ?',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          resposta.isEmpty ? '0' : resposta,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Row(
                        children: [
                          botaoNumero('1'),
                          botaoNumero('2'),
                          botaoNumero('3'),
                        ],
                      ),

                      Row(
                        children: [
                          botaoNumero('4'),
                          botaoNumero('5'),
                          botaoNumero('6'),
                        ],
                      ),

                      Row(
                        children: [
                          botaoNumero('7'),
                          botaoNumero('8'),
                          botaoNumero('9'),
                        ],
                      ),

                      Row(
                        children: [
                          botaoNumero('C', acao: limparResposta),
                          botaoNumero('0'),
                          botaoNumero('⌫', acao: apagarNumero),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: verificar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Responder',
                            style: TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
