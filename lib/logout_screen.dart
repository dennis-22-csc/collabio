import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/util.dart';
import 'package:provider/provider.dart';
import 'package:collabio/model.dart';
import 'package:go_router/go_router.dart';

class LogOutScreen extends StatefulWidget {
  const LogOutScreen({Key? key,}) : super(key: key);

  @override
  State<LogOutScreen> createState() => _LogOutScreenState();

}

class _LogOutScreenState extends State<LogOutScreen> {
  
  @override
  void initState() {
    super.initState();
    final profileInfoModel = Provider.of<ProfileInfoModel>(context, listen: false);
    logUserOut(profileInfoModel);
  }

  Future<void> logUserOut(ProfileInfoModel profileInfoModel) async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.goNamed("login");
    profileInfoModel.updateLogOutUserStatusTemp(true);
     });
    await FirebaseAuth.instance.signOut();
    SharedPreferencesUtil.setLogOutStatus(true);
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

