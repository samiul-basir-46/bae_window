import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'package:bea_window_app/helpers/notification_service.dart';
import 'space_screen_event.dart';
import 'space_screen_state.dart';
import '../services/realtime_sync_service.dart';
import '../services/presence_service.dart';
import '../models/bucket_list_model.dart';

class SpaceScreenBloc extends Bloc<SpaceScreenEvent, SpaceScreenState> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final RealtimeSyncService _syncService = RealtimeSyncService();
  final PresenceService _presenceService = PresenceService();

  StreamSubscription? _bucketSub;
  StreamSubscription? _anniversarySub;
  StreamSubscription? _nicknameSub;
  StreamSubscription? _presenceSub;
  StreamSubscription? _tasksSub;
  StreamSubscription? _momentsSub;

  String? _coupleId;
  String? _partnerUid;

  // Cached state properties
  List<BucketListItem> _cachedBucketList = [];
  DateTime? _cachedAnniversaryDate;
  String _cachedPartnerNickname = "Partner";
  bool _cachedIsPartnerOnline = false;
  List<SpaceMomentItem> _cachedMoments = [];
  double _cachedTaskProgress = 0.0;
  String _cachedNextTaskTitle = "No active tasks";

  SpaceScreenBloc() : super(const SpaceScreenInitial()) {
    on<LoadSpaceScreenDataEvent>(_onLoadSpaceScreenData);
    on<BucketListUpdatedEvent>(_onBucketListUpdated);
    on<AnniversaryUpdatedEvent>(_onAnniversaryUpdated);
    on<PartnerNicknameUpdatedEvent>(_onPartnerNicknameUpdated);
    on<PartnerPresenceUpdatedEvent>(_onPartnerPresenceUpdated);
    on<TasksUpdatedEvent>(_onTasksUpdated);
    on<MomentsUpdatedEvent>(_onMomentsUpdated);
    on<AddBucketItemEvent>(_onAddBucketItem);
    on<UpdateBucketItemEvent>(_onUpdateBucketItem);
    on<DeleteBucketItemEvent>(_onDeleteBucketItem);
    on<UpdateAnniversaryEvent>(_onUpdateAnniversary);
    on<SendSpaceLoveNoteEvent>(_onSendSpaceLoveNoteEvent);
  }

  Future<void> _onLoadSpaceScreenData(
    LoadSpaceScreenDataEvent event,
    Emitter<SpaceScreenState> emit,
  ) async {
    emit(const SpaceScreenLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        emit(const SpaceScreenError("User not authenticated"));
        return;
      }

      final profile = await _authService.getUserProfile(user.uid);
      if (profile == null) {
        emit(const SpaceScreenError("Failed to load user profile"));
        return;
      }

      final pairStatus = profile['pairStatus'] as String? ?? 'none';
      final coupleId = profile['pairId'] as String?;
      if (pairStatus != 'paired' || coupleId == null) {
        emit(const SpaceScreenError("You must be paired to access Space"));
        return;
      }

      _coupleId = coupleId;
      _partnerUid = await _authService.getPartnerUid(coupleId);

      // Start presence tracking for current user
      unawaited(_presenceService.updateUserPresence(user.uid, true));

      // Cancel any existing subs
      await _bucketSub?.cancel();
      await _anniversarySub?.cancel();
      await _nicknameSub?.cancel();
      await _presenceSub?.cancel();
      await _tasksSub?.cancel();
      await _momentsSub?.cancel();

      // Listen to Firestore Bucket List stream
      _bucketSub = _syncService.watchBucketList(coupleId).listen((items) {
        add(BucketListUpdatedEvent(items));
      });

      // Listen to Firestore Anniversary stream
      _anniversarySub = _syncService.watchAnniversary(user.uid).listen((date) {
        add(AnniversaryUpdatedEvent(date));
      });

      // Listen to Firestore Tasks stream
      _tasksSub = _syncService.watchTasks(coupleId).listen((tasks) {
        add(TasksUpdatedEvent(tasks));
      });

      // Listen to Firestore Moments stream
      _momentsSub = _syncService.watchMoments(coupleId).listen((moments) {
        add(MomentsUpdatedEvent(moments));
      });

      if (_partnerUid != null) {
        // Listen to Partner Nickname stream
        _nicknameSub = _syncService.watchPartnerNickname(_partnerUid!).listen((nickname) {
          add(PartnerNicknameUpdatedEvent(nickname));
        });

        // Listen to Partner Presence stream
        _presenceSub = _presenceService.watchPartnerPresence(_partnerUid!).listen((isOnline) {
          add(PartnerPresenceUpdatedEvent(isOnline));
        });
      }

      emit(SpaceScreenLoaded(
        bucketList: _cachedBucketList,
        anniversaryDate: _cachedAnniversaryDate,
        partnerNickname: _cachedPartnerNickname,
        isPartnerOnline: _cachedIsPartnerOnline,
        coupleId: coupleId,
        partnerUid: _partnerUid ?? '',
        recentMoments: _cachedMoments,
        taskProgress: _cachedTaskProgress,
        nextTaskTitle: _cachedNextTaskTitle,
      ));
    } catch (e) {
      emit(SpaceScreenError("Error loading space: $e"));
    }
  }

  void _onBucketListUpdated(BucketListUpdatedEvent event, Emitter<SpaceScreenState> emit) {
    _cachedBucketList = event.items;
    _emitLoaded(emit);
  }

  void _onAnniversaryUpdated(AnniversaryUpdatedEvent event, Emitter<SpaceScreenState> emit) {
    _cachedAnniversaryDate = event.date;
    _emitLoaded(emit);
  }

  void _onPartnerNicknameUpdated(PartnerNicknameUpdatedEvent event, Emitter<SpaceScreenState> emit) {
    if (event.nickname != null && event.nickname!.isNotEmpty) {
      _cachedPartnerNickname = event.nickname!;
    } else {
      _cachedPartnerNickname = "Partner";
    }
    _emitLoaded(emit);
  }

  void _onPartnerPresenceUpdated(PartnerPresenceUpdatedEvent event, Emitter<SpaceScreenState> emit) {
    _cachedIsPartnerOnline = event.isOnline;
    _emitLoaded(emit);
  }

  void _onTasksUpdated(TasksUpdatedEvent event, Emitter<SpaceScreenState> emit) {
    final tasks = event.tasks;
    if (tasks.isEmpty) {
      _cachedTaskProgress = 0.0;
      _cachedNextTaskTitle = "No active tasks";
    } else {
      final total = tasks.length;
      final completed = tasks.where((t) => t['status'] == 'completed').length;
      _cachedTaskProgress = completed / total;

      final activeTasks = tasks.where((t) => t['status'] != 'completed').toList();
      if (activeTasks.isEmpty) {
        _cachedNextTaskTitle = "All done! 🎉";
      } else {
        _cachedNextTaskTitle = activeTasks.last['title'] as String? ?? "No active tasks";
      }
    }
    _emitLoaded(emit);
  }

  void _onMomentsUpdated(MomentsUpdatedEvent event, Emitter<SpaceScreenState> emit) {
    _cachedMoments = event.moments.map((m) {
      String timeStr = "Just now";
      final createdAt = m['createdAt'];
      if (createdAt is Timestamp) {
        final date = createdAt.toDate();
        final diff = DateTime.now().difference(date);
        if (diff.inMinutes < 1) {
          timeStr = "Just now";
        } else if (diff.inHours < 1) {
          timeStr = "${diff.inMinutes}m ago";
        } else if (diff.inDays < 1) {
          timeStr = "${diff.inHours}h ago";
        } else {
          timeStr = DateFormat('MMM d').format(date);
        }
      }
      return SpaceMomentItem(
        user: m['user'] as String? ?? 'System',
        action: m['action'] as String? ?? '',
        time: timeStr,
        type: m['type'] as String? ?? 'note',
      );
    }).toList();
    _emitLoaded(emit);
  }

  Future<void> _onAddBucketItem(AddBucketItemEvent event, Emitter<SpaceScreenState> emit) async {
    if (_coupleId != null) {
      try {
        await _syncService.addBucketItem(_coupleId!, event.item);
      } catch (e) {
        dev.log("Error adding bucket item: $e", name: "SpaceScreenBloc");
      }
    }
  }

  Future<void> _onUpdateBucketItem(UpdateBucketItemEvent event, Emitter<SpaceScreenState> emit) async {
    if (_coupleId != null) {
      try {
        await _syncService.updateBucketItem(_coupleId!, event.item);
      } catch (e) {
        dev.log("Error updating bucket item: $e", name: "SpaceScreenBloc");
      }
    }
  }

  Future<void> _onDeleteBucketItem(DeleteBucketItemEvent event, Emitter<SpaceScreenState> emit) async {
    if (_coupleId != null) {
      try {
        await _syncService.deleteBucketItem(_coupleId!, event.itemId);
      } catch (e) {
        dev.log("Error deleting bucket item: $e", name: "SpaceScreenBloc");
      }
    }
  }

  Future<void> _onUpdateAnniversary(UpdateAnniversaryEvent event, Emitter<SpaceScreenState> emit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _syncService.updateAnniversary(user.uid, event.date);
      } catch (e) {
        dev.log("Error updating anniversary: $e", name: "SpaceScreenBloc");
      }
    }
  }

  Future<void> _onSendSpaceLoveNoteEvent(SendSpaceLoveNoteEvent event, Emitter<SpaceScreenState> emit) async {
    if (_coupleId != null) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          final name = userDoc.exists ? (userDoc.data()?['nickname'] as String? ?? currentUser.displayName ?? "Someone") : "Someone";

          // Add to Moments feed
          await _syncService.addMoment(
            _coupleId!,
            user: name,
            action: "sent a Love Note: '${event.note}'",
            type: "note",
          );

          await PushNotificationService.createLoveNoteEvent(event.note);
        }
      } catch (e, stack) {
        dev.log(
          'Could not create love-note notification event',
          name: 'SpaceScreenBloc',
          error: e,
          stackTrace: stack,
        );
      }
    }
  }

  void _emitLoaded(Emitter<SpaceScreenState> emit) {
    if (state is SpaceScreenLoaded) {
      emit((state as SpaceScreenLoaded).copyWith(
        bucketList: _cachedBucketList,
        anniversaryDate: _cachedAnniversaryDate,
        partnerNickname: _cachedPartnerNickname,
        isPartnerOnline: _cachedIsPartnerOnline,
        recentMoments: _cachedMoments,
        taskProgress: _cachedTaskProgress,
        nextTaskTitle: _cachedNextTaskTitle,
      ));
    }
  }

  @override
  Future<void> close() {
    _bucketSub?.cancel();
    _anniversarySub?.cancel();
    _nicknameSub?.cancel();
    _presenceSub?.cancel();
    _tasksSub?.cancel();
    _momentsSub?.cancel();
    return super.close();
  }
}
