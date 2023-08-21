import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:collabio/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:collabio/skill_edit.dart';
import 'package:collabio/general_profile_edit.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:collabio/model.dart';

class ProfileSection {
  String title;
  String content;
  List<String> tags;
  ProfileSection({required this.title, required this.content, required this.tags});
}

class ProfileSectionView extends StatefulWidget {
  final ProfileSection section;
  final Function()? selectProfilePicture;
  final File? profilePicture;

  const ProfileSectionView({
    required Key? key,
    required this.section,
    this.selectProfilePicture,
    this.profilePicture,
  }) : super(key: key);
  @override
  State<ProfileSectionView> createState() => _ProfileSectionViewState();

}

class _ProfileSectionViewState extends State<ProfileSectionView> {
  TextEditingController _textEditingController = TextEditingController();
  String? _email; 
  

  @override
  void initState() {
    super.initState();
    User user = FirebaseAuth.instance.currentUser!; 
    _email = user.email;
    _textEditingController = TextEditingController(text: widget.section.content);
   
  }
  
   void showEditDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
        return ProfileEditDialog(
        textEditingController: _textEditingController,
        email: _email!,
        title: widget.section.title,
        content: widget.section.content,
      );
      },
    );
  }

  void showSkillEditDialog(BuildContext context) {
  
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black45,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (BuildContext buildContext, Animation animation, Animation secondaryAnimation) {
      return SkillEditDialog(
        email: _email!,
        title: widget.section.title,
        content: widget.section.tags,
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return ListTile(
  title: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(widget.section.title, style: const TextStyle(fontSize: 15)),
      ),
      Align(
        alignment: Alignment.centerRight,
        child: IconButton(
        icon: const Icon(Icons.edit, size: 20),
        onPressed: () {
          if (widget.section.title == 'Skills') {
            showSkillEditDialog(context);
          } else {
            showEditDialog(context);
          }
        },
      ),
      )
    ],
  ),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.section.title == 'Skills') ...[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.section.tags.map((skill) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(skill),
            );
          }).toList(),
        ),
      ] else ...[
        Text(_textEditingController.text),
      ],
    ],
  ),
);


}

  
}

class ProfileSectionScreen extends StatefulWidget {
  const ProfileSectionScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSectionScreen> createState() => _ProfileSectionScreenState();
}

class _ProfileSectionScreenState extends State<ProfileSectionScreen> {
  late ProfileInfoModel _profileInfoModel;

  final List<ProfileSection> sections = [
    ProfileSection(title: 'First Name', content: '', tags: []),
    ProfileSection(title: 'Last Name', content: '', tags: []),
    ProfileSection(title: 'About', content: '', tags: []),
    ProfileSection(title: 'Skills', content: '', tags: []),
  ];

  @override
  void initState() {
    super.initState();
  }

  void selectProfilePicture() async {
    bool directoryExists = await Util.checkAndCreateDirectory(context);

    if (directoryExists) {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        File newProfilePicture = File(pickedImage.path);

        bool saved = await Util.saveProfilePicture(newProfilePicture);
        if (saved) {
          _profileInfoModel.updateProfilePicture();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileInfoModel = Provider.of<ProfileInfoModel>(context);    
    sections[0].content = profileInfoModel.firstName!;
    sections[1].content = profileInfoModel.lastName!;
    sections[2].content = profileInfoModel.about!;
    sections[3].tags = profileInfoModel.tags!;
    _profileInfoModel = profileInfoModel;

    return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.pop();
            },
          ),
          title: const Text('Your Profile')
        ),
        body: ListView.builder(
          itemCount: 1 + sections.length,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: profileInfoModel.profilePicture == null ? null : FileImage(profileInfoModel.profilePicture!),
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.bottomRight,
                          child: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: selectProfilePicture,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            return ProfileSectionView(key: UniqueKey(), section: sections[index - 1]);
          },
        ),
      );
  }

 
}

