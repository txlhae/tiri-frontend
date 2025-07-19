import 'package:flutter/material.dart';

class Reviews extends StatelessWidget {
  const Reviews({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: ThemeData.dark().colorScheme.surface,
      ),
      body: Center(
        child: Padding(
          padding:const EdgeInsets.all(20.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 80,
                backgroundColor: ThemeData.dark().colorScheme.surface,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("3", style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),),
                    Text("Out of 5 stars", style: TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onPrimary),),
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star),
                  Icon(Icons.star),
                  Icon(Icons.star),
                  Icon(Icons.star_border),
                  Icon(Icons.star_border),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                "Your rating",
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(
                height: 5,
              ),
              const Text(
                "rating",
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w300),
              ),
              const SizedBox(
                height: 5,
              ),
              const Text(
                "You have 200hrs",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}