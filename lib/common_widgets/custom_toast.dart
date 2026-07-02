import '../helpers/navigation_service.dart';
import 'app_toast.dart';

void customToastMessage(String title, String description, {ToastType type = ToastType.info}) {
  final context = NavigationService.navigatorKey.currentContext;
  if (context == null) return;

  ToastType toastType = type;
  if (type == ToastType.info) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('error') ||
        lowerTitle.contains('fail') ||
        lowerTitle.contains('wrong') ||
        lowerTitle.contains('incorrect') ||
        lowerTitle.contains('invalid')) {
      toastType = ToastType.error;
    } else if (lowerTitle.contains('success') ||
        lowerTitle.contains('save') ||
        lowerTitle.contains('complete') ||
        lowerTitle.contains('verified') ||
        lowerTitle.contains('update') ||
        lowerTitle.contains('done')) {
      toastType = ToastType.success;
    }
  }

  AppToast.show(
    context,
    title: title,
    message: description,
    type: toastType,
  );
}