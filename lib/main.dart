import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:rss_feed/news.dart';
import 'package:webfeed/webfeed.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_html/flutter_html.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rss_feed/constants.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          textTheme: const TextTheme(bodyText1: TextStyle(fontSize: 15))),
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  RssFeed? _rssFeed;
  final List<RssItem> _articles = [];
  final News _selectedNews = News(
      title: "Trang chủ", url: "https://vnexpress.net/rss/tin-moi-nhat.rss");

  //get rss feed data
  Future<RssFeed> getRssFeedData() async {
    try {
      final client = http.Client();
      final response = await client.get(Uri(
          scheme: "https",
          host: "vnexpress.net",
          path: "/rss/tin-moi-nhat.rss"));
      return RssFeed.parse(response.body);
    } catch (e) {
      print(e);
    }
    return RssFeed();
  }

  Future<void> launchUrl(String url) async {
    await launch(url);
    return;
  }

  updateFeed(feed) {
    setState(() {
      _rssFeed = feed;
    });
  }

  openWebView(url) {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => NewsWebView(url)));
  }

  @override
  void initState() {
    super.initState();

    _articles.clear();
    getRssFeedData().then((feed) {
      updateFeed(feed);
      for (RssItem item in feed.items!) {
        _articles.add(item);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: SvgPicture.network(
            "https://s1.vnecdn.net/vnexpress/restruct/i/v690/mobile_redesign/graphics/logo-vnexpress.svg",
            fit: BoxFit.fitHeight,
            placeholderBuilder: (BuildContext context) =>
                const CircularProgressIndicator(),
            alignment: Alignment.center,
          ),
          backgroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          color: const Color.fromARGB(255, 237, 240, 244),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: pages.map((page) {
                    return Container(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                      margin: const EdgeInsets.fromLTRB(3, 0, 3, 0),
                      decoration: page.title == _selectedNews.title
                          ? const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20)),
                              color: Color.fromARGB(255, 58, 134, 226),
                            )
                          : null,
                      child: Text(
                        page.title,
                        // style: TextStyle(
                        //   color: page.title == _selectedNews.title
                        //       ? Colors.white
                        //       : Color.fromARGB(255, 160, 160, 160),
                        //   fontWeight: FontWeight.bold,
                        //
                        // ).merge(Theme.of(context).textTheme.bodyText1),
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            ?.merge(TextStyle(
                              color: page.title == _selectedNews.title
                                  ? Colors.white
                                  : Color.fromARGB(255, 160, 160, 160),
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: ListView.builder(
                    itemCount: _articles.length,
                    itemBuilder: (BuildContext buildContext, int index) {
                      return Container(
                        child: Column(children: [
                          Text(utf8.decode(_articles[index].title!.codeUnits,
                              allowMalformed: true)),
                          Html(
                            data: utf8.decode(
                                _articles[index].description!.codeUnits,
                                allowMalformed: true),
                            onLinkTap: (url, _, __, ___) {
                              openWebView(url);
                            },
                          )
                        ]),
                      );
                    }),
              ),
            ],
          ),
        ));
  }
}

class NewsWebView extends StatelessWidget {
  String url;

  NewsWebView(this.url);

  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(
        builder: (BuildContext context) {
          return WebView(
            initialUrl: url,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated: (WebViewController wvcontroller) {
              _controller.complete(wvcontroller);
            },
            gestureNavigationEnabled: true,
          );
        },
      ),
    );
  }
}
