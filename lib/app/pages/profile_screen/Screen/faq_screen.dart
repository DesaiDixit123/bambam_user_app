import 'dart:convert';

import 'package:bam_bam_user/app/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  List<Map<String, dynamic>> _faqs = [];
  bool _isLoading = true;
  String? _error;
  int? _activeIndex;

  @override
  void initState() {
    super.initState();
    _fetchFaqs();
  }

  Future<void> _fetchFaqs() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await http
          .get(
            Uri.parse('https://apis.bambamcabs.com/user/faq?panelType=User'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final List rawFaqs = data['faqs'] as List? ?? [];
        setState(() {
          _faqs = rawFaqs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load FAQs. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsValue.appBg,
      appBar: AppBarWidget(
        onTapBack: () => Get.back(),
        title: '',
      ),
      body: RefreshIndicator(
        color: ColorsValue.appColor,
        onRefresh: _fetchFaqs,
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(color: ColorsValue.appColor),
              )
            : _error != null
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: ColorsValue.appColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: Styles.txtG5ColorsW40014,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _fetchFaqs,
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              color: ColorsValue.appColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _faqs.isEmpty
            ? ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: ColorsValue.appColor.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No FAQs available at the moment.',
                          style: Styles.txtG5ColorsW40014,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 8),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Frequently Asked ',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: ColorsValue.blackColor,
                            ),
                          ),
                          TextSpan(
                            text: 'Questions',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: ColorsValue.appColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Text(
                      'Find answers to the most common questions about our services.',
                      textAlign: TextAlign.center,
                      style: Styles.txtG5ColorsW40014.copyWith(fontSize: 13),
                    ),
                  ),

                  // FAQ Accordion List
                  ...List.generate(_faqs.length, (index) {
                    final faq = _faqs[index];
                    final isOpen = _activeIndex == index;
                    final question = faq['question']?.toString() ?? '';
                    final answer = faq['answer']?.toString() ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: ColorsValue.whiteColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOpen
                              ? ColorsValue.appColor.withOpacity(0.4)
                              : ColorsValue.borderColors,
                          width: isOpen ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          children: [
                            // Question row
                            InkWell(
                              onTap: () {
                                setState(() {
                                  _activeIndex = isOpen ? null : index;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        question,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isOpen
                                              ? ColorsValue.appColor
                                              : ColorsValue.blackColor,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedRotation(
                                      turns: isOpen ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 300),
                                      child: Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                        color: isOpen
                                            ? ColorsValue.appColor
                                            : ColorsValue.txtG7Color,
                                        size: 24,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Answer (animated expand)
                            AnimatedCrossFade(
                              firstChild: const SizedBox.shrink(),
                              secondChild: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: ColorsValue.appColor.withOpacity(0.04),
                                  border: Border(
                                    top: BorderSide(
                                      color: ColorsValue.appColor.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Text(
                                  answer,
                                  style: Styles.txtG5ColorsW40014.copyWith(
                                    fontSize: 13,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              crossFadeState: isOpen
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              duration: const Duration(milliseconds: 300),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
      ),
    );
  }
}
