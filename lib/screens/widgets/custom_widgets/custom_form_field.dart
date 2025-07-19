import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:kind_clock/controllers/auth_controller.dart';

class CustomFormField extends StatelessWidget {
  final String hintText;
  final bool haveObscure;
  final bool? isdescription;
  final bool? isphone;
  final TextEditingController textController;
  final String? Function(String?)? validator;
  final VoidCallback? onTapped;
  final String? iconSuffix;
  final TextInputType? keyboardType;
  final Country? selectedCountry;
  final List<TextInputFormatter>? inputFormatters;
  final void Function(String)? onChanged;



  const CustomFormField({
    super.key,
    required this.hintText,
    required this.haveObscure,
    required this.textController,
    this.validator,
    this.isdescription,
    this.iconSuffix,
    this.onTapped,
    this.isphone,
    this.keyboardType,
    this.selectedCountry,
    this.inputFormatters,
    this.onChanged
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AuthController>(builder: (controller) {
      return TextFormField(
        readOnly: iconSuffix != null ? true : false,
        style: const TextStyle(color: Colors.black),
        maxLines: isdescription != null ? 5 : 1,
        maxLength: isphone != null ? 10 : null,
        obscureText: haveObscure ? controller.isObscure.value : false,
        keyboardType:
            keyboardType ?? (isphone != null ? TextInputType.phone : null),
        decoration: InputDecoration(
          counterText: '',
          fillColor: Colors.white,
          filled: true,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(width: 0.5)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(width: 0.5)),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          alignLabelWithHint: true,
          prefixText: isphone == true && selectedCountry != null
          ? '+${selectedCountry!.phoneCode} '
          : null,
         suffixIcon: haveObscure
              ? IconButton(
                  onPressed: controller.toggleObscure,
                  icon: Icon(
                    controller.isObscure.value
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.grey,
                  ),
                )
              : IconButton(
                  onPressed: onTapped,
                  icon: SvgPicture.asset(iconSuffix ?? '')),
        ),
        controller: textController,
        inputFormatters: inputFormatters,
        validator: validator,
        onTap: onTapped,
        onChanged: onChanged,
      );
    });
  }
}
