import 'package:ebs_biometry/ebs_biometry.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EbsBiometry.configureSdk(
    appScheme: 'testexpample',
    infoSystem: 'infoSystem',
    appTitle: 'appTitle',
  ).then(print);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Content(),
      ),
    );
  }
}

class Content extends StatefulWidget {
  const Content({Key? key}) : super(key: key);

  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: Text('hasVerificationPermission'),
          onTap: () {
            EbsBiometry.hasVerificationPermission().then((v) => showSnackBar(v.toString()));
          },
        ),
        ListTile(
          title: Text('requestVerificationPermission'),
          onTap: () {
            EbsBiometry.requestVerificationPermission().then((v) => showSnackBar(v.toString()));
            ;
          },
        ),
        ListTile(
          title: Text('isEbsAppInstalled'),
          onTap: () {
            EbsBiometry.isEbsAppInstalled().then((v) => showSnackBar(v.toString()));
          },
        ),
        ListTile(
          title: Text('requestInstallApp'),
          onTap: () {
            EbsBiometry.requestInstallApp();
          },
        ),
        ListTile(
          title: Text('requestEsiaVerification'),
          onTap: () {
            EbsBiometry.requestEsiaVerification('test1').then((v) => showSnackBar(v.toString()));
          },
        ),
        ListTile(
          title: Text('requestEbsVerification'),
          onTap: () {
            EbsBiometry.requestEbsVerification('test1').then((v) => showSnackBar(v.toString()));
          },
        ),
      ],
    );
  }

  void showSnackBar(String message) {
    Scaffold.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
}
