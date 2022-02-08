import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:oneMail/Services/rating_service.dart';

import 'color_pallet.dart';

Widget reviews(BuildContext context, Rating rating, bool isDark) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: FittedBox(
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color:
              !isDark ? Colors.grey.shade100 : ColorPallete.darkModeSecondary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: RatingBar.builder(
                  initialRating: 0,
                  minRating: 1,
                  direction: Axis.horizontal,
                  itemCount: 5,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemSize: 35,
                  itemBuilder: (context, _) => const Icon(
                    AntDesign.star,
                    color: Colors.amber,
                  ),
                  onRatingUpdate: (rate) => rating.rating.value = rate.toInt(),
                ),
              ),
              InkWell(
                onTap: () => rating.rate(),
                child: Text(
                  "Rate us",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : ColorPallete.primaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => rating.isRatindApplicable.value = false,
                icon: Icon(
                  MaterialIcons.cancel,
                  color: Colors.red.shade700,
                ),
              )
            ],
          ),
        ),
      ),
    ),
  );
}
