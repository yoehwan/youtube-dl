import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ionicons/ionicons.dart';
import 'package:youtube_dl/views/play_view/src/play_card_view.dart';

import 'play_view_model.dart';

class PlayView extends StatelessWidget {
  PlayView({Key? key}) : super(key: key);
  final PlayViewModel _viewModel = PlayViewModel();

  Widget _listView() {
    return Obx(() {
      return ListView.builder(
        itemCount: _viewModel.dlList.length,
        itemBuilder: (_, index) {
          return PlayCardView(
            item: _viewModel.dlList[index],
            onTapPlay: _viewModel.onSelectItem,
          );
        },
      );
    });
  }

  Widget _controlButtons() {
    return Row(
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Ionicons.play_back),
        ),
        IconButton(
          onPressed: _viewModel.onTapPlay,
          icon: const Icon(Ionicons.play),
        ),
        IconButton(
          onPressed: _viewModel.onTapPause,
          icon: const Icon(Ionicons.pause),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Ionicons.play_forward),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _listView()),
        _controlButtons(),
      ],
    );
  }
}