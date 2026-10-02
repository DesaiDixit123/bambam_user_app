import 'package:bam_bam_user/app/theme/theme.dart';
import 'package:bam_bam_user/data/helpers/api_wrapper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class FacilityIconWidget extends StatelessWidget {
  final dynamic logo;
  final String text;
  final String type; // 'inclusion', 'exclusion', 'feature'
  final double size;
  final Color? color;

  const FacilityIconWidget({
    super.key,
    required this.logo,
    required this.text,
    this.type = 'feature',
    this.size = 22.0,
    this.color,
  });

  /// Resolves the full URL for dynamic images coming from admin/backend API
  static String resolveImageUrl(dynamic logoRaw) {
    if (logoRaw == null) return '';
    final path = logoRaw.toString().trim();
    if (path.isEmpty || path == 'null' || path == 'undefined') return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    if (path.startsWith('blob:') || path.startsWith('data:')) {
      return path;
    }
    if (path.startsWith('/uploads/')) {
      return 'https://apis.bambamcabs.com$path';
    }
    if (path.startsWith('uploads/')) {
      return 'https://apis.bambamcabs.com/$path';
    }
    return '${ApiWrapper.imageUrl}$path';
  }

  Widget _buildFallback() {
    final activeColor = color ??
        (type == 'exclusion' ? Colors.red : ColorsValue.appColor);

    if (type == 'inclusion') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: activeColor,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.check,
            size: size * 0.65,
            color: activeColor,
          ),
        ),
      );
    }

    if (type == 'exclusion') {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.red,
            width: 1.5,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.close,
            size: 13,
            color: Colors.red,
          ),
        ),
      );
    }

    // Feature fallback - intelligent keyword matching like website
    final t = text.toLowerCase().trim();
    IconData iconData = Icons.check_circle_outline;

    if (t.contains('luggage') || t.contains('bag') || t.contains('boot')) {
      iconData = Icons.luggage_outlined;
    } else if (t.contains('seat') ||
        t.contains('passenger') ||
        t.contains('person') ||
        t.contains('seater')) {
      iconData = Icons.airline_seat_recline_normal;
    } else if (t.contains('fuel') ||
        t.contains('fare') ||
        t.contains('petrol') ||
        t.contains('diesel') ||
        t.contains('gas') ||
        t.contains('charges')) {
      iconData = Icons.local_gas_station_outlined;
    } else if (t.contains('toll') ||
        t.contains('border') ||
        t.contains('tax') ||
        t.contains('permit')) {
      iconData = Icons.toll_outlined;
    } else if (t.contains('driver') ||
        t.contains('allowance') ||
        t.contains('chauffeur') ||
        t.contains('da')) {
      iconData = Icons.person_pin_circle_outlined;
    } else if (t.contains('ac') ||
        t.contains('air condition') ||
        t.contains('climate')) {
      iconData = Icons.ac_unit;
    } else if (t.contains('clean') ||
        t.contains('sanitiz') ||
        t.contains('hygiene') ||
        t.contains('safety')) {
      iconData = Icons.verified_user_outlined;
    } else if (t.contains('gps') ||
        t.contains('track') ||
        t.contains('navigation') ||
        t.contains('fastag')) {
      iconData = Icons.navigation_outlined;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: activeColor,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Icon(
          iconData,
          size: size * 0.65,
          color: activeColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final url = resolveImageUrl(logo);
    final fallback = _buildFallback();

    if (url.isEmpty) {
      return fallback;
    }

    final isSvg = url.toLowerCase().contains('.svg');

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: isSvg
            ? SvgPicture.network(
                url,
                width: size,
                height: size,
                fit: BoxFit.contain,
                placeholderBuilder: (_) => fallback,
              )
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.contain,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              ),
      ),
    );
  }
}
