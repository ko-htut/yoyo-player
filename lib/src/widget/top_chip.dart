import 'package:flutter/material.dart';

Widget topChip(Widget data, Function fun) {
  return InkWell(
    onTap: fun as void Function()?,
    child: Container(
      margin: EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
          color: Colors.grey, borderRadius: BorderRadius.circular(5)),
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: data,
      ),
    ),
  );
}
