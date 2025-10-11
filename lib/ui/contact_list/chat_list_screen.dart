import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/providers/delayed_relay_error_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/config/providers/pinned_chats_provider.dart';
import 'package:whitenoise/config/providers/polling_provider.dart';
import 'package:whitenoise/config/providers/profile_ready_card_visibility_provider.dart';
import 'package:whitenoise/config/providers/relay_status_provider.dart';
import 'package:whitenoise/config/providers/welcomes_provider.dart';
import 'package:whitenoise/domain/models/chat_list_item.dart';
import 'package:whitenoise/domain/services/background_sync_service.dart';
import 'package:whitenoise/domain/services/notification_service.dart';
import 'package:whitenoise/routing/routes.dart';
import 'package:whitenoise/src/rust/api/welcomes.dart';
import 'package:whitenoise/ui/contact_list/new_chat_bottom_sheet.dart';
import 'package:whitenoise/ui/contact_list/services/welcome_notification_service.dart';
import 'package:whitenoise/ui/contact_list/widgets/chat_list_active_account_avatar.dart';
import 'package:whitenoise/ui/contact_list/widgets/chat_list_item_tile.dart';
import 'package:whitenoise/ui/contact_list/widgets/profile_ready_card.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_app_bar.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_fade.dart';
import 'package:whitenoise/ui/core/ui/wn_heads_up.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static final Logger _log = Logger('ChatListScreen');
  String _searchQuery = '';

  static const double _searchThresholdIOS = 0.1;
  static const double _searchThresholdAndroid = 0.08;
  static const double _refreshThresholdIOS = 0.25;
  static const double _refreshThresholdAndroid = 0.2;
  static const double _triggerResetOffset = -20.0;
  static const Duration _loadingAnimationDuration = Duration(milliseconds: 500);
  static const Duration _animationDelay = Duration(milliseconds: 500);

  late final PollingNotifier _pollingNotifier;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _loadingAnimationController;
  late Animation<double> _loadingAnimation;

  bool _hasSearchTriggered = false;
  bool _hasRefreshTriggered = false;
  bool _isLoadingData = false;
  bool _isRefreshing = false;
  bool _isSearchVisible = false;
  final int _loadingSkeletonCount = 8;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollingNotifier = ref.read(pollingProvider.notifier);
    _initializeControllers();
    _setupScrollListener();
    _scheduleInitialSetup();
    _requestNotificationsPermission();
    _initializeBackgroundSync();
  }

  Future<void> _initializeBackgroundSync() async {
    try {
      await BackgroundSyncService.initialize();
      await BackgroundSyncService.registerAllTasks();
    } catch (e) {
      _log.severe('Failed to initialize background sync: $e');
    }
  }

  Future<void> _requestNotificationsPermission() async {
    try {
      await NotificationService.requestPermissions();
    } catch (e, st) {
      _log.severe('Failed to get notifications permission: $e $st');
    }
  }

  void _initializeControllers() {
    _loadingAnimationController = AnimationController(
      duration: _loadingAnimationDuration,
      vsync: this,
    );
    _loadingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingAnimationController, curve: Curves.easeInOut),
    );
  }

  void _setupScrollListener() {
    _scrollController.addListener(_onScroll);
  }

  void _scheduleInitialSetup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WelcomeNotificationService.initialize(context);
      WelcomeNotificationService.setupWelcomeNotifications(ref);
      _loadData();
      _pollingNotifier.startPolling();
    });
  }

  Future<void> _loadData() async {
    if (_isLoadingData) return;
    _setLoadingState(isLoading: true);
    try {
      await _loadAllProviderData();
    } catch (e, st) {
      _log.severe('Error loading data: $e $st');
    } finally {
      _setLoadingState(isLoading: false);
    }
  }

  void _setLoadingState({required bool isLoading}) {
    setState(() {
      _isLoadingData = isLoading;
      if (isLoading) {
        _isSearchVisible = false;
      }
    });
  }

  Future<void> _loadAllProviderData() async {
    await Future.wait([
      ref.read(welcomesProvider.notifier).loadWelcomes(),
      ref.read(groupsProvider.notifier).loadGroups(),
      ref.read(relayStatusProvider.notifier).refreshStatuses(),
    ]);
  }

  void _onScroll() {
    final currentOffset = _scrollController.offset;

    _resetTriggersIfNeeded(currentOffset);

    if (_canProcessScrollGestures) {
      _processScrollGestures(currentOffset);
    }
  }

  void _resetTriggersIfNeeded(double currentOffset) {
    if (currentOffset > _triggerResetOffset) {
      _hasSearchTriggered = false;
      _hasRefreshTriggered = false;
    }
  }

  bool get _canProcessScrollGestures => !_isLoadingData && !_isRefreshing;

  bool get isInLoadingState => _isLoadingData;

  void _processScrollGestures(double currentOffset) {
    final pullDistance = -currentOffset;
    final thresholds = _calculateThresholds();

    if (_shouldTriggerRefresh(pullDistance, thresholds.refresh)) {
      _triggerRefresh();
    } else if (_shouldTriggerSearch(pullDistance, thresholds.search)) {
      _triggerSearch();
    }
  }

  ({double search, double refresh}) _calculateThresholds() {
    final screenHeight = 1.sh;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    return (
      search: screenHeight * (isAndroid ? _searchThresholdAndroid : _searchThresholdIOS),
      refresh: screenHeight * (isAndroid ? _refreshThresholdAndroid : _refreshThresholdIOS),
    );
  }

  bool _shouldTriggerRefresh(double pullDistance, double refreshThreshold) {
    return pullDistance >= refreshThreshold && !_hasRefreshTriggered;
  }

  bool _shouldTriggerSearch(double pullDistance, double searchThreshold) {
    return pullDistance >= searchThreshold &&
        !_hasSearchTriggered &&
        !_isSearchVisible &&
        !_hasRefreshTriggered;
  }

  void _triggerRefresh() {
    _hasRefreshTriggered = true;
    _performRefresh();
  }

  void _triggerSearch() {
    _hasSearchTriggered = true;
    setState(() {
      _isSearchVisible = true;
    });
    FocusScope.of(context).requestFocus(_searchFocusNode);
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _isSearchVisible = false;
    });
    _unfocusSearchIfNeeded();
  }

  void _unfocusSearchIfNeeded() {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  Future<void> _performRefresh() async {
    if (_isRefreshing) return;
    _setRefreshState(isRefreshing: true);
    try {
      await _executeRefreshSequence();
    } catch (e, st) {
      _log.severe('Error during refresh: $e $st');
    } finally {
      _setRefreshState(isRefreshing: false);
    }
  }

  void _setRefreshState({required bool isRefreshing}) {
    setState(() {
      _isRefreshing = isRefreshing;
      if (isRefreshing) {
        _isSearchVisible = false;
        _hasSearchTriggered = false;
      } else {
        _hasRefreshTriggered = false;
      }
    });
  }

  Future<void> _executeRefreshSequence() async {
    _loadingAnimationController.forward();
    await _loadData();
    await Future.delayed(_animationDelay);
    await _loadingAnimationController.reverse();
  }

  @override
  void dispose() {
    _pollingNotifier.stopPolling();
    _searchController.dispose();
    _scrollController.dispose();
    _loadingAnimationController.dispose();
    WelcomeNotificationService.clearContext();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // On resume, re register all tasks with update policy
      _initializeBackgroundSync();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch both groups and welcomes
    final groupList = ref.watch(groupsProvider.select((state) => state.groups)) ?? [];
    final welcomesList = ref.watch(welcomesProvider.select((state) => state.welcomes)) ?? [];
    final visibilityAsync = ref.watch(profileReadyCardVisibilityProvider);
    final pinnedChats = ref.watch(pinnedChatsProvider);
    final pinnedChatsNotifier = ref.watch(pinnedChatsProvider.notifier);

    final chatItems = <ChatListItem>[];

    for (final group in groupList) {
      final lastMessage = ref.watch(
        chatProvider.select(
          (state) => state.getLatestMessageForGroup(group.mlsGroupId),
        ),
      );
      final isPinned = pinnedChats.contains(group.mlsGroupId);
      chatItems.add(
        ChatListItem.fromGroup(
          group: group,
          lastMessage: lastMessage,
          isPinned: isPinned,
        ),
      );
    }

    // Add pending welcomes as chat items
    final pendingWelcomes = welcomesList.where((welcome) => welcome.state == WelcomeState.pending);
    for (final welcome in pendingWelcomes) {
      chatItems.add(ChatListItem.fromWelcome(welcome: welcome));
    }

    // Use the separatePinnedChats method with search filtering
    final separatedChats = pinnedChatsNotifier.separatePinnedChats(
      chatItems,
      searchQuery: _searchQuery,
    );
    final filteredChatItems = [...separatedChats.pinned, ...separatedChats.unpinned];

    final delayedRelayErrorState = ref.watch(delayedRelayErrorProvider);
    final shouldShowRelayError = delayedRelayErrorState.shouldShowBanner;

    return GestureDetector(
      onTap: _unfocusSearchIfNeeded,
      child: Scaffold(
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                WnAppBar.sliver(
                  title: Padding(
                    padding: EdgeInsets.only(left: 16.w),
                    child: ChatListActiveAccountAvatar(
                      onTap: () {
                        _unfocusSearchIfNeeded();
                        context.push(Routes.settings);
                      },
                    ),
                  ),
                  actions: [
                    IconButton(
                      onPressed:
                          shouldShowRelayError
                              ? null
                              : () {
                                _unfocusSearchIfNeeded();
                                NewChatBottomSheet.show(context);
                              },
                      icon: WnImage(
                        shouldShowRelayError ? AssetsPaths.icOffChat : AssetsPaths.icAddNewChat,
                        size: 21.w,
                        color: context.colors.solidNeutralWhite.withValues(
                          alpha: shouldShowRelayError ? 0.5 : 1.0,
                        ),
                      ),
                    ),
                    Gap(8.w),
                  ],
                  pinned: true,
                ),
                if (shouldShowRelayError)
                  SliverToBoxAdapter(
                    child:
                        WnHeadsUp(
                          title: 'chats.noRelaysConnected'.tr(),
                          subtitle: 'chats.appWontWorkUntilRelay'.tr(),
                          action: InkWell(
                            child: Text(
                              'chats.connectRelays'.tr(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: context.colors.primary,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            onTap: () => context.push(Routes.settingsNetwork),
                          ),
                        ).animate().fadeIn(),
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
                                      'chats.checkingForNewMessages'.tr(),
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
                              hintText: 'chats.searchChats'.tr(),
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                              decoration: InputDecoration(
                                prefixIcon: Padding(
                                  padding: EdgeInsets.all(12.w),
                                  child: WnImage(
                                    AssetsPaths.icSearch,
                                    color: context.colors.primary,

                                    size: 20.w,
                                  ),
                                ),
                                suffixIcon: GestureDetector(
                                  onTap: _clearSearch,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.w),
                                    child: WnImage(
                                      AssetsPaths.icClose,
                                      color: context.colors.primary,

                                      size: 20.w,
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fade(),
                      ),
                    ),
                  SliverPadding(
                    padding: EdgeInsets.only(bottom: 32.h),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        if (isInLoadingState) {
                          return const ChatListTileLoading();
                        }
                        final item = filteredChatItems[index];
                        return ChatListItemTile(
                          item: item,
                          onTap: _unfocusSearchIfNeeded,
                        );
                      },
                      itemCount:
                          isInLoadingState ? _loadingSkeletonCount : filteredChatItems.length,
                      separatorBuilder: (context, index) {
                        if (isInLoadingState) {
                          return Gap(8.w);
                        }

                        // Add divider between pinned and unpinned sections
                        if (index == separatedChats.pinned.length - 1 &&
                            separatedChats.unpinned.isNotEmpty) {
                          return Container(
                            height: 2.h,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                            ),
                          );
                        }

                        return Gap(8.w);
                      },
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
            WnImage(
              AssetsPaths.icWhiteNoiseSvg,
              width: 69.17.w,
              height: 53.20.h,
              color: context.colors.primary,
            ),
            Gap(12.h),
            Text(
              'chats.emptySlogan'.tr(),
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
