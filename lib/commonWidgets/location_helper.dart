import 'package:flutter/material.dart';

class LocationBadge extends StatelessWidget {
  final bool hasLocation;
  final String? address;
  final VoidCallback? onTap;

  const LocationBadge({
    super.key,
    required this.hasLocation,
    this.address,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasLocation
              ? const Color(0xFF8B5CF6).withOpacity(0.1)
              : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasLocation
                ? const Color(0xFF8B5CF6).withOpacity(0.3)
                : Colors.orange.shade200,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasLocation ? Icons.location_on : Icons.location_off,
              size: 14,
              color: hasLocation
                  ? const Color(0xFF8B5CF6)
                  : Colors.orange.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              hasLocation
                  ? (address ?? 'Location set')
                  : 'Location unavailable',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasLocation
                    ? const Color(0xFF8B5CF6)
                    : Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}