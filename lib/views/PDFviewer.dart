import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:retry/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:userboffee/Core/Models/d_withFile.dart';
import 'package:userboffee/Core/Models/note_model.dart';
import 'package:userboffee/Core/config/options.dart';
import 'package:userboffee/Core/constants/colors.dart';
import 'package:userboffee/Core/constants/linksapi.dart';
import 'package:userboffee/Core/provider/Note_provider.dart';
import 'package:userboffee/Core/service/real/crud.dart';
import 'package:userboffee/views/baises_screen/Details.dart';

class PDFviewer extends StatefulWidget {
  const PDFviewer({
    super.key,
    required this.detail_File,
  });
  final Detail_withFile detail_File;

  @override
  State<PDFviewer> createState() => _PDFviewerState();
}

class _PDFviewerState extends State<PDFviewer> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  TextEditingController review_con = TextEditingController();
  TextEditingController notecontroller = TextEditingController();
  String? currentPdfFile;
  int indexPage = 0;
  int selectedColor = 1;
  double ratingValue = 0;
  String? shelfId;
  int? userId;
  final Crud crud = Crud();
  GlobalKey x = GlobalKey();

  @override
  void initState() {
    super.initState();
    fetchUserId();
    fetchShelfId().then((_) {
      _initializePDFView();
    });
  }

  Future<void> _initializePDFView() async {
    await Future.delayed(const Duration(seconds: 2));
    await _checkAndClearForNewUser();
    if (currentPdfFile != widget.detail_File.file!.file) {
      setState(() {
        indexPage = 0;
        currentPdfFile = widget.detail_File.file!.file;
      });
    }
    await _loadLastPage();
    print("PDFView initialization complete");
  }

  Future<void> _checkAndClearForNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastUser = prefs.getString('lastUser');
    String currentUser = userId.toString();

    if (lastUser != currentUser) {
      await prefs.remove('lastPage_${widget.detail_File.file!.id}');
      await prefs.remove('lastFile_${widget.detail_File.file!.id}');
      await prefs.setString('lastUser', currentUser);
    }
  }

  Future<void> _loadLastPage() async {
    final prefs = await SharedPreferences.getInstance();
    int? lastPage = prefs.getInt('lastPage_${widget.detail_File.file!.id}');
    int? lastFileId = prefs.getInt('lastFile_${widget.detail_File.file!.id}');

    if (lastPage != null && widget.detail_File.file!.id == lastFileId) {
      setState(() {
        indexPage = lastPage;
      });
      _pdfViewerController.jumpToPage(indexPage);
    } else {
      setState(() {
        indexPage = 0;
      });
    }
  }

  Future<void> _savePageIndex(int pageIndex) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPage_${widget.detail_File.file!.id}', pageIndex);
    await prefs.setInt(
        'lastFile_${widget.detail_File.file!.id}', widget.detail_File.file!.id);
  }

  Future<void> fetchUserId() async {
    try {
      var response = await http
          .get(
            Uri.parse(link_userDetails),
            headers: getoptions(),
          )
          .timeout(const Duration(seconds: 30));
      print("Server response: ${response.body}");

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic> &&
            responseBody['success'] == true) {
          setState(() {
            userId = responseBody['data']['id'];
            print("User_id: $userId");
          });
        } else {
          print('Failed to fetch User id');
        }
      } else {
        print('Failed to fetch User id');
      }
    } catch (e) {
      print(e);
      print('An error occurred');
    }
  }

  Future<void> add_Rate() async {
    try {
      Map<String, dynamic> body = {
        "book_id": widget.detail_File.file!.id,
        "rate": ratingValue.toInt(),
      };
      print("Rating Book ID: ${widget.detail_File.file!.id}");
      var response = await crud.postrequest(
        link_rating,
        body,
        headers: getoptions2(),
      );
      print("rating is: $ratingValue");
      print("id is: ${widget.detail_File.file!.id}");
      print("Response: $response");

      if (response is Map && response['success'] == true) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => BookDetailsPage(
                  detail_File: widget.detail_File,
                )));
        print("success");
      } else {
        print("fail");
        print("Server response: $response");
      }
    } catch (e) {
      print("ERROR $e");
    }
  }

  Future<void> add_Note() async {
    try {
      print("Note Book ID: ${widget.detail_File.file!.id}");
      final bookId = widget.detail_File.file!.id;
      final url = "$link_storeNote/$bookId";

      Map<String, dynamic> body = {
        "page_num": indexPage,
        "body": notecontroller.text,
        "book_id": widget.detail_File.file!.id,
        "color": selectedColor,
      };
      var response = await crud.postrequest(
        url,
        body,
        headers: getoptions2(),
      );
      print("index page is: $indexPage");
      print("Response: $response");

      if (response is Map && response['success'] == true) {
        NoteModel newNote = NoteModel.fromJson(response['data']);
        NoteProvider.notesNotifier.value = [
          ...NoteProvider.notesNotifier.value,
          newNote
        ];

        AnimatedSnackBar(
          duration: const Duration(seconds: 3),
          builder: (context) {
            return MaterialAnimatedSnackBar(
              messageText: "The note has been added to your profile".tr(),
              type: AnimatedSnackBarType.success,
              foregroundColor: Colors.white,
              backgroundColor: medium_Brown,
            );
          },
        ).show(context);
        Navigator.pop(context);
        notecontroller.clear();
        print("success note");
      } else {
        print("fail");
        print("Server response: $response");
      }
    } catch (e) {
      print("ERROR $e");
    }
  }

  Future<void> fetchShelfId() async {
    // ignore: unused_local_variable
    const r = RetryOptions(maxAttempts: 3);
    try {
      final bookId = widget.detail_File.file!.id;

      var response = await http
          .get(
            Uri.parse("$link_enough/$bookId"),
            headers: getoptions(),
          )
          .timeout(
            const Duration(seconds: 30),
          );
      print("Server response: ${response.body}");

      if (response.statusCode == 200) {
        var responseBody = json.decode(response.body);
        if (responseBody is Map<String, dynamic> &&
            responseBody['success'] == true) {
          setState(() {
            shelfId = responseBody['data']['Shelf_id'].toString();
            print("self_id: $shelfId");
          });
        } else {
          print('Failed to fetch User Details');
        }
      } else {
        print('Failed to fetch User Details');
      }
    } catch (e) {
      // ignore: unused_label
      retryIf:
      (e) => e is SocketException || e is TimeoutException;
      print(e);
      print('An error occurred');
    }
  }

  update_progress() async {
    try {
      print("----------------------------------------------");
      if (shelfId == null) {
        print("Shelf ID is null. Cannot update progress.");
        return;
      }
      final url = "$link_progress/$shelfId";

      print("Shelf ID: $shelfId");
      int index = indexPage + 1;
      Map<String, dynamic> body = {
        "progress": index,
      };
      var response = await crud.postrequest(
        url,
        body,
        headers: getoptions2(),
      );

      print("Index page is: $index");
      print("Response: $response");

      if (response is Map) {
        if (response['success'] == true) {
          print("Update progress success");
        } else {
          print("Update progress failed");
          print("Server response message: ${response['message']}");
        }
      } else {
        print("Unexpected response format: $response");
      }
    } catch (e) {
      print("ERROR: $e");

      if (e is HttpException) {
        print("HttpException: ${e.message}");
      } else if (e is SocketException) {
        print("SocketException: ${e.message}");
      } else {
        print("Unknown error: $e");
      }
    }
  }

  AlertDialog _alertDialog(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF8F1),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.65,
        height: MediaQuery.of(context).size.height * 0.2,
        child: TextFormField(
          showCursor: false,
          maxLines: 10,
          controller: notecontroller,
          decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "add your note....".tr(),
              hintStyle: const TextStyle(color: Color(0XFFA5A5A5))),
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<int>(
                dropdownColor: const Color(0xFFFFF8F1),
                value: selectedColor,
                items: [
                  DropdownMenuItem(value: 1, child: Text("Green".tr())),
                  DropdownMenuItem(value: 2, child: Text("Blue".tr())),
                  DropdownMenuItem(value: 3, child: Text("Pink".tr())),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedColor = value!;
                  });
                },
              ),
              ElevatedButton(
                onPressed: () {
                  add_Note();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: medium_Brown,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    padding: const EdgeInsets.only(
                        left: 25, right: 25, top: 10, bottom: 10)),
                child: Text("Add".tr(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    )),
              ),
            ],
          ),
        ),
      ],
    );
  }

  SnackBar snakB(BuildContext context) {
    return SnackBar(
      dismissDirection: DismissDirection.up,
      duration: const Duration(days: 365),
      backgroundColor: const Color(0xFFFFF8F1),
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      content: StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            height: MediaQuery.of(context).size.height * 0.50,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.celebration,
                    color: medium_Brown,
                    size: 50,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Congratulations!'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      color: medium_Brown,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You have read this book completely and obtained 5 coffee beans.'
                        .tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'What is your rate for this book?'.tr(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      fontSize: 25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  RatingBar.builder(
                    initialRating: ratingValue,
                    minRating: 1,
                    unratedColor: Colors.amber.withAlpha(50),
                    itemCount: 5,
                    itemSize: 50.0,
                    itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      setState(() {
                        ratingValue = rating;
                      });
                    },
                    updateOnDrag: true,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${'Your rating:'.tr()}$ratingValue',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await add_Rate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF94745B),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Submit'.tr(),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 23),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double percent = ((100 * indexPage) / widget.detail_File.file!.total_pages);
    String finalPercent = percent.toStringAsFixed(0);
    //const String baseUrl = "http://10.0.2.2:8000";
    String baseUrl = "http://10.0.2.2:8000";
    final String filePath = widget.detail_File.file!.file;
    final String pdfUrl = "$baseUrl$filePath";
    print("!!!:$filePath");
    print("+++++++++the pdfUrl: $pdfUrl");
    print(Exception().toString());

    //print(widget.detail_File.file!.file.toString());
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: insidbook_color,
          title: Text(widget.detail_File.file!.title),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_outlined,
              color: dark_Brown,
              size: 35,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return _alertDialog(context);
                  },
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(no_color),
                elevation: MaterialStateProperty.all(0),
              ),
              child: Icon(
                Icons.add_comment_outlined,
                color: dark_Brown,
                size: 30,
              ),
            ),
          ],
        ),
        body: FutureBuilder(
            future: _initializePDFView(),
            builder: (context, snapshot) {
              return Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.698,
                    child: SfPdfViewer.network(
                      enableDocumentLinkAnnotation: true,
                      pdfUrl,
                      controller: _pdfViewerController,
                      canShowScrollHead: false,
                      pageSpacing: 2,
                      onTextSelectionChanged:
                          (PdfTextSelectionChangedDetails details) {
                        if (details.selectedText != null) {
                          print(details.selectedText);
                        }
                      },
                      onPageChanged: (details) {
                        _savePageIndex(details.newPageNumber);
                        print('$indexPage');
                      },
                      initialScrollOffset: const Offset(10, 10),
                      onDocumentLoadFailed: (details) {
                        print("Failed to load PDF: ${details.description}");
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFFFFF8F1),
                            content: Text(
                                "${"Failed to load PDF:".tr()} ${details.description}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                )),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      width: double.infinity,
                      height: MediaQuery.of(context).size.height * 0.2,
                      decoration: BoxDecoration(color: insidbook_color),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 40, top: 15),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (indexPage > 0) {
                                      await update_progress();
                                      setState(() {
                                        indexPage--;
                                        _pdfViewerController
                                            .jumpToPage(indexPage);
                                        _savePageIndex(indexPage);
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: medium_Brown,
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                      top: 15,
                                      bottom: 15,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios,
                                    color: white,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 40, top: 15),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    if (indexPage <
                                        widget.detail_File.file!.total_pages) {
                                      setState(() {
                                        indexPage++;
                                        _pdfViewerController
                                            .jumpToPage(indexPage);
                                        _savePageIndex(indexPage);
                                        print("$indexPage");
                                      });
                                      await update_progress();
                                    }
                                    if (indexPage ==
                                        widget.detail_File.file!.total_pages) {
                                      SnackBar snackBar = snakB(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                    }
                                    await update_progress();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: medium_Brown,
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 10,
                                      top: 15,
                                      bottom: 15,
                                    ),
                                  ),
                                  child: Icon(
                                    indexPage <
                                            widget.detail_File.file!
                                                    .total_pages -
                                                1
                                        ? Icons.arrow_forward_ios
                                        : Icons.done,
                                    color: white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Center(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6.0),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 24.0),
                              ),
                              child: Slider(
                                autofocus: true,
                                activeColor: medium_Brown,
                                inactiveColor: white,
                                value: indexPage.toDouble().clamp(
                                    1.0,
                                    (widget.detail_File.file!.total_pages)
                                        .toDouble()),
                                min: 0,
                                max: (widget.detail_File.file!.total_pages)
                                    .toDouble(),
                                divisions: (widget
                                    .detail_File.file!.total_pages) as int,
                                onChanged: (double value) async {
                                  setState(() {
                                    indexPage = value.toInt();
                                    _pdfViewerController.jumpToPage(indexPage);
                                    _savePageIndex(indexPage);
                                  });
                                  await update_progress();
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 40),
                                  child: Text(
                                    "${"Page".tr()} $indexPage/${widget.detail_File.file!.total_pages}",
                                    style:
                                        TextStyle(fontSize: 15, color: white),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 35),
                                  child: Text(
                                    "${"Completed ".tr()}$finalPercent%",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: dark_Brown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }));
  }
}
