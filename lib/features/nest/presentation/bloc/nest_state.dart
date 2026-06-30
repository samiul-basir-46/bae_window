import 'package:flutter/foundation.dart';

@immutable
abstract class NestState {
  const NestState();
}

class NestInitial extends NestState {
  const NestInitial();
}

class NestLoading extends NestState {
  const NestLoading();
}

class NestLoaded extends NestState {
  final bool isVaultLocked;
  final bool isFocusMode;
  final String selectedTheme;
  final String partnerName;
  final bool isLeftAvatarOnTop;
  final bool isPaired;
  final String userAvatarUrl;
  final String partnerAvatarUrl;

  const NestLoaded({
    required this.isVaultLocked,
    required this.isFocusMode,
    required this.selectedTheme,
    required this.partnerName,
    required this.isLeftAvatarOnTop,
    required this.isPaired,
    required this.userAvatarUrl,
    required this.partnerAvatarUrl,
  });

  NestLoaded copyWith({
    bool? isVaultLocked,
    bool? isFocusMode,
    String? selectedTheme,
    String? partnerName,
    bool? isLeftAvatarOnTop,
    bool? isPaired,
    String? userAvatarUrl,
    String? partnerAvatarUrl,
  }) {
    return NestLoaded(
      isVaultLocked: isVaultLocked ?? this.isVaultLocked,
      isFocusMode: isFocusMode ?? this.isFocusMode,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      partnerName: partnerName ?? this.partnerName,
      isLeftAvatarOnTop: isLeftAvatarOnTop ?? this.isLeftAvatarOnTop,
      isPaired: isPaired ?? this.isPaired,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      partnerAvatarUrl: partnerAvatarUrl ?? this.partnerAvatarUrl,
    );
  }
}

class NestError extends NestState {
  final String message;
  const NestError(this.message);
}
