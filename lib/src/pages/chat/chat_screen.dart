import 'package:carbon_icons/carbon_icons.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:flutter_chat_reactions/model/menu_item.dart';
import 'package:flutter_chat_reactions/utilities/hero_dialog_route.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/src/pages/chat/widgets/chat_input.dart';
import 'package:whitenoise/src/pages/chat/widgets/contact_info.dart';
import 'package:whitenoise/src/pages/chat/widgets/message_widget.dart';
import '../../core/utils/app_colors.dart';
import '../../core/utils/assets_paths.dart';
import '../../models/message.dart';
import 'states/chat_audio_state.dart';
import 'dummy_data/dummy_data.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const List<MenuItem> menuItems = [
    reply,
    forward,
    copy,
    delete,
  ];

  static const List<MenuItem> myMessageMenuItems = [
    reply,
    forward,
    edit,
    copy,
    delete,
  ];

  static const MenuItem reply = MenuItem(
    label: 'Reply',
    icon: CarbonIcons.reply,
  );

  static const MenuItem copy = MenuItem(
    label: 'Copy',
    icon: CarbonIcons.copy,
  );

  static const MenuItem forward = MenuItem(
    label: 'Forward',
    icon:  CarbonIcons.send,
  );

  static const MenuItem edit = MenuItem(
    label: 'Edit',
    icon: CarbonIcons.edit,
  );

  static const MenuItem delete = MenuItem(
    label: 'Delete',
    icon:  CarbonIcons.delete,
    isDestuctive: true,
  );

  void showEmojiBottomSheet({
    required Message message,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 310,
          child: EmojiPicker(
            onEmojiSelected: ((category, emoji) {
              // pop the bottom sheet
              Navigator.pop(context);
              addReactionToMessage(
                message: message,
                reaction: emoji.emoji,
              );
            }),
          ),
        );
      },
    );
  }

  // add reaction to message
  void addReactionToMessage({
    required Message message,
    required String reaction,
  }) {
    message.reactions.add(reaction);
    // update UI
    setState(() {});
  }

  void sendNewMessage(Message newMessage){
    setState(() {
      messages.insert(0,newMessage);
    });
  }


  @override
  void initState() {
    super.initState();
  }


  @override
  void dispose() {
    super.dispose();
    context.read<ChatAudioCubit>().dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.colorE2E2E2,),
          onPressed: () {},
        ),
        title: const ContactInfo(),
        actions: [
          GestureDetector(
            onTap: () => (),
            child: Container(margin: EdgeInsets.only(right: 15), child: Icon(CarbonIcons.search, color: AppColors.colorE2E2E2,) ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 8.0,
            right: 8.0,
          ),
          child: Column(
            children: [
              Expanded(
                child: // list view builder for example messages
                ListView.builder(
                  reverse: true,
                  itemCount: messages.length+1,
                  itemBuilder: (BuildContext context, int index) {
                    //get chatting user info
                    if(index == messages.length){
                      return Container(
                        padding: EdgeInsets.only(left: 30, right: 30),
                        child: Column(
                          children: [
                            Gap(80),
                            CircleAvatar(
                              backgroundImage: AssetImage(AssetsPaths.icImage),
                              radius: 30,
                            ),
                            Gap(5),
                            Text('Marek', style: TextStyle(color: AppColors.color202320, fontSize: 23),),
                            Gap(10),
                            Text('marek@crupek.com', style: TextStyle(color: AppColors.color202320,),),
                            Gap(10),
                            Text.rich(
                              textAlign: TextAlign.center,
                              TextSpan(
                                text: 'efaeg ', // Default style
                                style: TextStyle(color: AppColors.color202320,),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'eaeed ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color202320),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'eaeed ',
                                    style: TextStyle(color: AppColors.color202320),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color202320),
                                  ),
                                  TextSpan(
                                    text: 'eaeed ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color202320),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'eaeed ',
                                    style: TextStyle(color: AppColors.color202320),
                                  ),
                                  TextSpan(
                                    text: 'kkase ',
                                    style: TextStyle(color: AppColors.color727772),
                                  ),
                                  TextSpan(
                                    text: 'kka',
                                    style: TextStyle(color: AppColors.color202320),
                                  ),
                                ],
                              ),
                            ),
                            Gap(10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CarbonIcons.email, color: AppColors.color727772, size: 14,),
                                Gap(5),
                                Text.rich(
                                  textAlign: TextAlign.center,
                                  TextSpan(
                                    text: 'Chat invite sent to ', // Default style
                                    style: TextStyle(color: AppColors.color727772,),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: "Marek",
                                        style: TextStyle(color: AppColors.color202320),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Gap(10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(CarbonIcons.checkmark, color: AppColors.color727772, size: 14,),
                                Gap(5),
                                Text.rich(
                                  textAlign: TextAlign.center,
                                  TextSpan(
                                    text: 'Marek', // Default style
                                    style: TextStyle(color: AppColors.color202320,),
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: " accepted the invite",
                                        style: TextStyle(color: AppColors.color727772),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Gap(30),

                          ],
                        ),
                      );
                    }else{
                      // get message
                      final message = messages[index];
                      return GestureDetector(
                        // wrap your message widget with a [GestureDectector] or [InkWell]
                        onLongPress: () {
                          // navigate with a custom [HeroDialogRoute] to [ReactionsDialogWidget]
                          Navigator.of(context).push(
                            HeroDialogRoute(
                              builder: (context) {
                                return ReactionsDialogWidget(
                                  id: message.id, // unique id for message
                                  menuItems: message.isMe?myMessageMenuItems:menuItems,
                                  messageWidget: MessageWidget(
                                      message: message), // message widget
                                  onReactionTap: (reaction) {
                                    print('reaction: $reaction');

                                    if (reaction == '➕') {
                                      // show emoji picker container
                                      showEmojiBottomSheet(
                                        message: message,
                                      );
                                    } else {
                                      // add reaction to message
                                      addReactionToMessage(
                                        message: message,
                                        reaction: reaction,
                                      );
                                    }
                                  },
                                  onContextMenuTap: (menuItem) {
                                    print('menu item: $menuItem');
                                    // handle context menu item
                                  },
                                  // align widget to the right for my message and to the left for contact message
                                  // default is [Alignment.centerRight]
                                  widgetAlignment: message.isMe
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                );
                              },
                            ),
                          );
                        },
                        // wrap message with [Hero] widget
                        child: Hero(
                          tag: message.id,
                          child: MessageWidget(message: message),
                        ),
                      );
                    }
                  },
                ),
              ),
              // bottom chat input
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: ChatInput(padding: const EdgeInsets.all(0), onSend: sendNewMessage) // BottomChatField(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
