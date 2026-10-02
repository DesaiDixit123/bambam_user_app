// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:bam_bam_user/app/app.dart';
// ignore_for_file: must_be_immutable

class CustomButton extends StatelessWidget {
  CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.leading,
    this.textStyle,
    this.heightBtn,
    this.widthBtn,
    this.radius,
    this.backgroundColor,
    this.isBorder,
    this.bordercolors,
    this.isColor,
    this.isboxsedo,
    this.boxShadows,
    this.isLoading = false,
  });

  void Function()? onPressed;
  String? text;
  Widget? leading;
  TextStyle? textStyle;
  double? radius;
  double? widthBtn;
  double? heightBtn;
  Color? backgroundColor;
  Color? bordercolors;
  bool? isBorder;
  bool? isColor;
  bool? isboxsedo;
  List<BoxShadow>? boxShadows;
  bool isLoading;

  @override
  Widget build(BuildContext context) {
    TextStyle? finalTextStyle = textStyle;
    if (backgroundColor == ColorsValue.appColor || backgroundColor == ColorsValue.primaryColor || isColor == true) {
      finalTextStyle = (textStyle ?? Styles.txtBlackColorW60016).copyWith(color: ColorsValue.whiteColor);
    }

    return Container(
      height: heightBtn ?? Dimens.fourtyFive,
      width: widthBtn ?? double.maxFinite,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius ?? Dimens.twelve),
        border: isBorder ?? false
            ? Border.all(
                width: Dimens.one,
                color: bordercolors ?? ColorsValue.borderColors,
              )
            : Border.all(
                width: Dimens.zero,
                color: bordercolors ?? ColorsValue.borderColors,
              ),
        boxShadow: boxShadows ??
            (isboxsedo == true
                ? [
                    const BoxShadow(
                      color: Color(0x99F4F5FA),
                      offset: Offset(0, -3),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ]
                : []),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius ?? Dimens.twelve),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: Dimens.twenty,
                    width: Dimens.twenty,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (backgroundColor == ColorsValue.appColor || isColor == true)
                            ? Colors.white
                            : ColorsValue.appColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (leading != null) ...[
                        leading!,
                        Dimens.boxWidth10,
                      ],
                      Text(text ?? "", style: finalTextStyle),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
