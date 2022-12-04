import 'package:flutter/material.dart';
import 'package:gem/models/widgets/entity/lastfm/profile_stack.dart';
import 'package:gem/models/widgets/entity/lastfm/scoreboard.dart';
import 'package:gem/models/widgets/entity/lastfm/tag_chips.dart';
import 'package:gem/models/widgets/entity/lastfm/wiki_view.dart';
import 'package:gem/models/widgets/entity/lastfm/your_scrobbles_view.dart';
import 'package:share_plus/share_plus.dart';

import '../../../services/generic.dart';
import '../../../services/lastfm/lastfm.dart';
import '../../../services/lastfm/track.dart';
import '../../../util/formatters.dart';
import '../../base/app_bar.dart';
import '../../base/future_builder_view.dart';
import '../../base/scrobble_button.dart';
import '../../base/two_up.dart';
import '../entity_image.dart';
import 'album_view.dart';
import 'artist_view.dart';
import 'love_button.dart';

class TrackView extends StatelessWidget {
  final Track track;

  const TrackView({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final friendUsername = ProfileStack.of(context).friendUsername;
    return FutureBuilderView<LTrack>(
      futureFactory: track is LTrack
          ? () => Future.value(track as LTrack)
          : () => Lastfm.getTrack(track),
      baseEntity: track,
      builder: (track) => Scaffold(
        appBar: createAppBar(
          track.name,
          subtitle: track.artist?.name,
          actions: [
            IconButton(
              icon: Icon(Icons.adaptive.share),
              onPressed: () {
                Share.share(track.url);
              },
            ),
            ScrobbleButton(entity: track),
          ],
        ),
        body: TwoUp(
          entity: track,
          listItems: [
            Scoreboard(
              statistics: {
                'Scrobbles': track.playCount,
                'Listeners': track.listeners,
                'Your scrobbles': track.userPlayCount,
                if (friendUsername != null)
                  "$friendUsername's scrobbles":
                      Lastfm.getTrack(track, username: friendUsername)
                          .then((value) => value.userPlayCount),
                if (track.userPlayCount > 0 && track.duration > 0)
                  'Total listen time': formatDuration(Duration(
                      milliseconds: track.userPlayCount * track.duration)),
              },
              statisticActions: {
                if (track.userPlayCount > 0)
                  'Your scrobbles': () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => YourScrobblesView(track: track),
                      ),
                    );
                  },
                if (friendUsername != null)
                  "$friendUsername's scrobbles": () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => YourScrobblesView(
                          track: track,
                          username: friendUsername,
                        ),
                      ),
                    );
                  }
              },
              actions: [
                LoveButton(track: track),
              ],
            ),
            if (track.topTags.tags.isNotEmpty) ...[
              const Divider(),
              TagChips(topTags: track.topTags),
            ],
            if (track.wiki != null && track.wiki!.isNotEmpty) ...[
              const Divider(),
              WikiTile(entity: track, wiki: track.wiki!),
            ],
            if (track.artist != null || track.album != null) const Divider(),
            if (track.artist != null)
              ListTile(
                leading: EntityImage(entity: track.artist!),
                title: Text(track.artist!.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ArtistView(artist: track.artist!)));
                },
              ),
            if (track.album != null)
              ListTile(
                leading: EntityImage(entity: track.album!),
                title: Text(track.album!.name),
                subtitle:
                    track.artist != null ? Text(track.artist!.name) : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AlbumView(album: track.album!)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
