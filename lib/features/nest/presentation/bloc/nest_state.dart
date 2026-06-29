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

  const NestLoaded({
    required this.isVaultLocked,
    required this.isFocusMode,
    required this.selectedTheme,
    required this.partnerName,
    required this.isLeftAvatarOnTop,
  });

  NestLoaded copyWith({
    bool? isVaultLocked,
    bool? isFocusMode,
    String? selectedTheme,
    String? partnerName,
    bool? isLeftAvatarOnTop,
  }) {
    return NestLoaded(
      isVaultLocked: isVaultLocked ?? this.isVaultLocked,
      isFocusMode: isFocusMode ?? this.isFocusMode,
      selectedTheme: selectedTheme ?? this.selectedTheme,
      partnerName: partnerName ?? this.partnerName,
      isLeftAvatarOnTop: isLeftAvatarOnTop ?? this.isLeftAvatarOnTop,
    );
  }
}

class NestError extends NestState {
  final String message;
  const NestError(this.message);
}
