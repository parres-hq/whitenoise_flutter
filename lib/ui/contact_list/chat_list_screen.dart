import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/polling_provider.dart';
import 'package:whitenoise/config/providers/profile_provider.dart';
import 'package:whitenoise/config/providers/profile_ready_card_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/services/welcome_notification_service.dart';
import 'package:whitenoise/ui/contact_list/widgets/chat_list_item_tile.dart';
import 'package:whitenoise/ui/contact_list/widgets/profile_avatar.dart';
import 'package:whitenoise/ui/contact_list/widgets/profile_ready_card.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_fade.dart';
import 'package:whitenoise/ui/core/ui/custom_app_bar.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> with TickerProviderStateMixin {
  late final PollingNotifier _pollingNotifier;
  bool _isSearchVisible = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingData = false;
  bool _isRefreshing = false;
  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;
  late AnimationController _searchAnimationController;

  // Pull velocity tracking
  double _lastScrollOffset = 0;
  DateTime _lastScrollTime = DateTime.now();
  double _pullVelocity = 0;
  bool _hasSearchTriggered = false;
  bool _hasRefreshTriggered = false;

  @override
  void initState() {
    super.initState();

    // Store reference to notifier early to avoid ref access in dispose
    _pollingNotifier = ref.read(pollingProvider.notifier);

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingAnimationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WelcomeNotificationService.initialize(context);
      WelcomeNotificationService.setupWelcomeNotifications(ref);
      // Load initial data
      _loadData();
      // Start polling for data updates
      _pollingNotifier.startPolling();
    });
  }

  Future<void> _loadData() async {
    // Load initial data for groups, welcomes, and profile
    if (_isLoadingData) return;
    setState(() {
      _isSearchVisible = false;
      _isLoadingData = true;
    });
    await Future.wait([
      ref.read(welcomesProvider.notifier).loadWelcomes(),
      ref.read(groupsProvider.notifier).loadGroups(),
      ref.read(profileProvider.notifier).fetchProfileData(),
    ]);

    setState(() {
      _isLoadingData = false;
    });
  }

  void _onScroll() {
    final currentTime = DateTime.now();
    final currentOffset = _scrollController.offset;
    final deltaTime = currentTime.difference(_lastScrollTime).inMilliseconds;

    if (deltaTime > 0) {
      final deltaOffset = currentOffset - _lastScrollOffset;
      _pullVelocity = deltaOffset / deltaTime * 1000;
    }

    _lastScrollOffset = currentOffset;
    _lastScrollTime = currentTime;

    if (currentOffset > -20) {
      _hasSearchTriggered = false;
      _hasRefreshTriggered = false;
    }

    if (currentOffset < -50 && !_isLoadingData && !_isRefreshing) {
      if (_pullVelocity < -2000 && !_hasRefreshTriggered) {
        _hasRefreshTriggered = true;
        _performRefresh();
      }
      // Slow pull (low velocity) = search
      else if (_pullVelocity > -1000 &&
          currentOffset <= -80 &&
          !_hasSearchTriggered &&
          !_isSearchVisible) {
        _hasSearchTriggered = true;
        setState(() {
          _isSearchVisible = true;
        });
      }
    }
  }

  Future<void> _performRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _isSearchVisible = false;
      _hasSearchTriggered = false;
    });
    _loadingAnimationController.forward();

    await _loadData();
    // Wait a bit for smooth animation
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadingAnimationController.reverse();

    setState(() {
      _isRefreshing = false;
      _hasRefreshTriggered = false;
    });
  }

  @override
  void dispose() {
    _pollingNotifier.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _loadingAnimationController.dispose();
    _searchAnimationController.dispose();
    WelcomeNotificationService.clearContext();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch both groups and welcomes
    final groupList = ref.watch(groupsProvider.select((state) => state.groups)) ?? [];
    final welcomesList = ref.watch(welcomesProvider.select((state) => state.welcomes)) ?? [];
    final visibilityAsync = ref.watch(profileReadyCardVisibilityProvider);

    // Cache profile data to avoid unnecessary rebuilds
    final profileData = ref.watch(profileProvider);
    final currentUserName = profileData.valueOrNull?.displayName ?? '';
    final userFirstLetter =
        currentUserName.isNotEmpty == true ? currentUserName[0].toUpperCase() : '';
    final profileImagePath = profileData.valueOrNull?.picture ?? '';

    final chatItems = <ChatListItem>[];

    for (final group in groupList) {
      final lastMessage = ref.watch(
        chatProvider.select(
          (state) => state.getLatestMessageForGroup(group.mlsGroupId),
        ),
      );
      chatItems.add(
        ChatListItem.fromGroup(
          groupData: group,
          lastMessage: lastMessage,
        ),
      );
    }

    // Add pending welcomes as chat items
    final pendingWelcomes = welcomesList.where((welcome) => welcome.state == WelcomeState.pending);
    for (final welcome in pendingWelcomes) {
      chatItems.add(ChatListItem.fromWelcome(welcomeData: welcome));
    }

    // Sort by date created (most recent first)
    chatItems.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

    // Filter chat items based on search query
    final filteredChatItems =
        _searchQuery.isEmpty
            ? chatItems
            : chatItems.where((item) {
              final searchLower = _searchQuery.toLowerCase();
              return item.displayName.toLowerCase().contains(searchLower) ||
                  item.subtitle.toLowerCase().contains(searchLower) ||
                  (item.lastMessage?.content?.toLowerCase().contains(searchLower) ?? false);
            }).toList();

    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                CustomAppBar.sliver(
                  title: Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16.r),
                      onTap: () {
                        if (_searchFocusNode.hasFocus) {
                          _searchFocusNode.unfocus();
                        }
                        context.push(Routes.settings);
                      },
                      child: ProfileAvatar(
                        profileImageUrl: profileImagePath,
                        userFirstLetter: userFirstLetter,
                      ),
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed: () {
                        if (_searchFocusNode.hasFocus) {
                          _searchFocusNode.unfocus();
                        }
                        NewChatBottomSheet.show(context);
                      },
                      icon: Image.asset(
                        AssetsPaths.icAddNewChat,
                        width: 32.w,
                        height: 32.w,
                      ),
                    ),
                    Gap(8.w),
                  ],
                  pinned: true,
                ),
                if (chatItems.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyGroupList(),
                  )
                else ...[
                  if (_isRefreshing)
                    SliverToBoxAdapter(
                      child: AnimatedBuilder(
                        animation: _loadingAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _loadingAnimation.value,
                            child: Container(
                              margin: EdgeInsets.all(
                                32.w,
                              ).copyWith(
                                bottom: _loadingAnimation.value * 30.h,
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16.w,
                                      height: 16.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3.sp,
                                        backgroundColor: context.colors.border,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          context.colors.primary,
                                        ),
                                      ),
                                    ),
                                    Gap(12.w),
                                    Text(
                                      'Checking for new messages…',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w500,
                                        color: context.colors.mutedForeground,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  if (_isSearchVisible)
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
                      sliver: SliverToBoxAdapter(
                        child:
                            WnTextFormField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              hintText: 'Search Chats',
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  CarbonIcons.search,
                                  size: 24.w,
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _isSearchVisible = false;
                                    });
                                  },
                                  child: Icon(
                                    CarbonIcons.close,
                                    size: 24.w,
                                  ),
                                ),
                              ),
                            ).animate().fade(),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.only(top: 8.h, bottom: 32.h),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final item = filteredChatItems[index];
                        return ChatListItemTile(
                          item: item,
                          onTap: () {
                            if (_searchFocusNode.hasFocus) {
                              _searchFocusNode.unfocus();
                            }
                          },
                        );
                      },
                      itemCount: filteredChatItems.length,
                      separatorBuilder: (context, index) => Gap(8.w),
                    ),
                  ),
                ],
              ],
            ),

            if (chatItems.isNotEmpty)
              Positioned(bottom: 0, left: 0, right: 0, height: 54.h, child: const WnBottomFade()),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: visibilityAsync.when(
            data: (showCard) => showCard ? const ProfileReadyCard() : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

class _EmptyGroupList extends StatelessWidget {
  const _EmptyGroupList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              AssetsPaths.icWhiteNoiseSvg,
              width: 69.17.w,
              height: 53.20.h,
              colorFilter: ColorFilter.mode(
                context.colors.primary,
                BlendMode.srcIn,
              ),
            ),
            Gap(12.h),
            Text(
              'Decentralized. Uncensorable.\nSecure Messaging.',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.mutedForeground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
