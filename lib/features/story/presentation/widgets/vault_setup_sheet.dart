import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class VaultSetupSheet extends StatefulWidget {
  final Function(String pin, bool enableBiometrics) onSetup;

  const VaultSetupSheet({super.key, required this.onSetup});

  @override
  State<VaultSetupSheet> createState() => _VaultSetupSheetState();
}

class _VaultSetupSheetState extends State<VaultSetupSheet> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _enableBiometrics = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: AppColors.navBgColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.w,
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                UIHelper.verticalSpace(24.h),
                Text(
                  "Setup Private Vault",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UIHelper.verticalSpace(6.h),
                Text(
                  "Secure your most private memories with a custom 4-digit PIN.",
                  style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 12.sp,
                  ),
                ),
                UIHelper.verticalSpace(24.h),
                // PIN Input
                _buildPinField(
                  controller: _pinController,
                  label: "Enter 4-Digit PIN",
                  hint: "••••",
                ),
                UIHelper.verticalSpace(16.h),
                // Confirm PIN Input
                _buildPinField(
                  controller: _confirmPinController,
                  label: "Confirm PIN",
                  hint: "••••",
                ),
                UIHelper.verticalSpace(24.h),
                // Enable Biometrics Toggle Switch
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Enable Biometric Unlock",
                            style: GoogleFonts.dmSans(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "Unlock the vault using your Fingerprint or Face ID",
                            style: GoogleFonts.dmSans(
                              color: Colors.white38,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _enableBiometrics,
                      onChanged: (val) {
                        setState(() {
                          _enableBiometrics = val;
                        });
                      },
                      activeThumbColor: AppColors.primaryPink,
                      activeTrackColor:
                          AppColors.primaryPink.withValues(alpha: 0.3),
                    ),
                  ],
                ),
                UIHelper.verticalSpace(100.h),
              ],
            ),
          ),
          Positioned(
            left: 24.w,
            right: 24.w,
            bottom: 24.h,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () {
                  final pin = _pinController.text.trim();
                  final confirmPin = _confirmPinController.text.trim();

                  if (pin.length != 4 || int.tryParse(pin) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("PIN must be exactly 4 digits!"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  if (pin != confirmPin) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("PIN and Confirm PIN do not match!"),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }

                  widget.onSetup(pin, _enableBiometrics);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Private Vault Enabled successfully!"),
                      backgroundColor: AppColors.primaryPink,
                    ),
                  );
                },
                child: Text(
                  "Enable Vault",
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white70,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        UIHelper.verticalSpace(8.h),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          style: GoogleFonts.dmSans(
              color: Colors.white, fontSize: 18.sp, letterSpacing: 8.w),
          decoration: InputDecoration(
            counterText: "",
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(
                color: Colors.white24, fontSize: 18.sp, letterSpacing: 8.w),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.primaryPurple),
            ),
          ),
        ),
      ],
    );
  }
}
