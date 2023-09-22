import 'dart:developer';

import 'package:chat_gpt/image_assets.dart';
import 'package:chat_gpt/shared/components/chat_widget.dart';
import 'package:chat_gpt/shared/components/my_divider.dart';
import 'package:chat_gpt/shared/components/navigator.dart';
import 'package:chat_gpt/shared/components/text_form_field.dart';
import 'package:chat_gpt/shared/components/text_widget.dart';
import 'package:chat_gpt/shared/providers/chats_provider.dart';
import 'package:chat_gpt/shared/providers/models_provider.dart';
import 'package:chat_gpt/shared/style/color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isTyping = false;

  late TextEditingController textEditingController;
  late ScrollController _listScrollController;
  late FocusNode focusNode;
  @override
  void initState() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // List<ChatModel> chatList = [];
  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final modelsProvider = Provider.of<ModelsProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leadingWidth: double.infinity,
        automaticallyImplyLeading: false,
        leading: Container(
          width: 335,
          height: 64,
          clipBehavior: Clip.antiAlias,
          decoration: const BoxDecoration(),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    padding: EdgeInsetsDirectional.zero,
                    icon: const ImageIcon(AssetImage(Assets.imagesArrowBack)),
                    onPressed: () {
                      pop(context);
                    },
                  ),
                  Text(
                    'Back',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  SvgPicture.asset(Assets.imagesLogo),
                  const SizedBox(width: 5),
                ],
              ),
              const MyDivider(),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: chatProvider.chatList.isEmpty
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                chatProvider.chatList.isEmpty ? const Spacer() : Container(),
                chatProvider.chatList.isEmpty
                    ? Text(
                        'Ask anything, get your answer',
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppMainColors.whiteColor
                                      .withOpacity(0.4000000059604645),
                                ),
                      )
                    : Flexible(
                        child: ListView.builder(
                            controller: _listScrollController,
                            itemCount: chatProvider
                                .getChatList.length, //chatList.length,
                            itemBuilder: (context, index) {
                              return ChatWidget(
                                msg: chatProvider.getChatList[index]
                                    .msg, // chatList[index].msg,
                                chatIndex: chatProvider.getChatList[index]
                                    .chatIndex, //chatList[index].chatIndex,
                                shouldAnimate:
                                    chatProvider.getChatList.length - 1 ==
                                        index,
                              );
                            }),
                      ),
                if (_isTyping) ...[
                  Container(
                    width: 61,
                    height: 43,
                    padding: const EdgeInsets.all(12),
                    decoration: ShapeDecoration(
                      color: Colors.white.withOpacity(0.20000000298023224),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                          bottomRight: Radius.circular(8),
                        ),
                      ),
                    ),
                    child: const SpinKitThreeBounce(
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
                const SizedBox(
                  height: 15,
                ),
                DefaultTextFormField(
                  controller: textEditingController,
                  keyboardType: TextInputType.multiline,
                  suffixPressed: () async {
                    await sendMessageFCT(
                        modelsProvider: modelsProvider,
                        chatProvider: chatProvider);
                  },
                  validate: (String? value) {
                    if (value!.trim().isEmpty) {
                      return "Please type a message";
                    }
                    return null;
                  },
                  hint: '',
                  suffix: const AssetImage(Assets.imagesSend),
                ),
              ]),
        ),
      ),
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut);
  }

  Future<void> sendMessageFCT(
      {required ModelsProvider modelsProvider,
      required ChatProvider chatProvider}) async {
    if (_isTyping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "You cant send multiple messages at a time",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "Please type a message",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      String msg = textEditingController.text;
      setState(() {
        _isTyping = true;
        chatProvider.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });
      await chatProvider.sendMessageAndGetAnswers(
          msg: msg, chosenModelId: modelsProvider.getCurrentModel);
      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TextWidget(
          label: error.toString(),
        ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        scrollListToEND();
        _isTyping = false;
      });
    }
  }
}
