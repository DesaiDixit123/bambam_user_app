import 'dart:async';

import 'package:bam_bam_user/app/app.dart';
import 'package:bam_bam_user/app/widgets/droup_down_widgets.dart';
import 'package:bam_bam_user/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MyTicketlistScreen extends StatefulWidget {
  const MyTicketlistScreen({super.key});

  @override
  State<MyTicketlistScreen> createState() => _MyTicketlistScreenState();
}

class _MyTicketlistScreenState extends State<MyTicketlistScreen> {
  final ProfileController controller = Get.find<ProfileController>();

  // Search + status filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = '';
  Timer? _debounce;

  static const List<String> _statusOptions = [
    'All',
    'Pending',
    'In Progress',
    'Resolved',
  ];

  @override
  void initState() {
    super.initState();
    // initial load
    controller.fetchTicketsWithoutPagination();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      controller.fetchTicketsWithoutPagination(
        search: query.trim(),
        status: _selectedStatus == 'All' ? '' : _selectedStatus,
        showLoader: false,
      );
    });
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status ?? '';
    });
    controller.fetchTicketsWithoutPagination(
      search: _searchController.text.trim(),
      status: (status == null || status == 'All') ? '' : status,
      showLoader: false,
    );
  }

  String _statusLabel(Map<String, dynamic> ticket) {
    final status = (ticket['status'] ?? '').toString();
    if (status.isEmpty) return 'Pending';
    return status;
  }

  String _ticketId(Map<String, dynamic> ticket) {
    // prefer ticket_no, then _id
    return ticket['ticket_no']?.toString() ?? ticket['_id']?.toString() ?? '—';
  }

  String _issueType(Map<String, dynamic> ticket) {
    return ticket['issue_type']?.toString() ?? '—';
  }

  String _description(Map<String, dynamic> ticket) {
    return ticket['description']?.toString() ?? '—';
  }

  // choose badge asset by status — keep same assets you had in UI
  String _statusAsset(String status) {
    status = status.toLowerCase();
    if (status.contains('resolved')) {
      return AssetConstants.Green_CN;
    } else if (status.contains('pending')) {
      return AssetConstants.Red_CN;
    } else if (status.contains('progress') || status.contains('in progress')) {
      return AssetConstants.yello_CN;
    } else {
      return AssetConstants.yello_CN;
    }
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final ticketNo = _ticketId(ticket);
    final status = _statusLabel(ticket);
    final issue = _issueType(ticket);
    final desc = _description(ticket);

    return InkWell(
      borderRadius: BorderRadius.circular(Dimens.twelve),
      onTap: () async {
        final id = ticket['_id']?.toString() ?? ticket['ticket_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          await controller.fetchTicketDetails(id);
          RouteManagement.gotoTicketDetilesScreen();
        } else {
          Utility.showMessage('Ticket id not available', MessageType.error, null, 'ok');
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: ColorsValue.l4CB,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          borderRadius: BorderRadius.circular(Dimens.twelve),
        ),
        child: Padding(
          padding: Dimens.edgeInsets20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // header row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Ticket ID #$ticketNo",
                    style: Styles.whiteColorW70014.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(_statusAsset(status)),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Padding(
                      padding: Dimens.edgeInsets8,
                      child: Text(
                        status.tr,
                        style: status.toLowerCase().contains('resolved')
                            ? Styles.txtGreenColorW60014
                            : status.toLowerCase().contains('pending')
                                ? Styles.txtRedColorW60014
                                : Styles.txtG7Colors40014,
                      ),
                    ),
                  ),
                ],
              ),
              Dimens.boxHeight25,
              Text(issue, style: Styles.txtBlackColorW40014),
              Dimens.boxHeight8,
              Text(desc, style: Styles.txtG7Colors40014),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        onTapBack: () {
          Get.back();
        },
        title: "My Tickets",
      ),
      backgroundColor: ColorsValue.appBg,
      bottomSheet: Padding(
        padding: Dimens.edgeInsets20_30_20_30,
        child: CustomButton(
          text: "Add Ticket",
          textStyle: Styles.txtBlackColorW40014,
          backgroundColor: ColorsValue.appColor,
          onPressed: () {
            RouteManagement.gotoCreatTicketScreen();
          },
        ),
      ),
      body: GetBuilder<ProfileController>(
        builder: (pc) {
          final tickets = pc.tickets;

          // Search bar + status filter (always visible)
          final filterSection = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field
              CustomTextFormField(
                preIocns: true,
                heightBtn: Dimens.fourtySix,
                style: Styles.txtBlackColorW40014,
                readOnly: false,
                hintText: 'Search tickets...'.tr,
                textEditingController: _searchController,
                onChanged: _onSearchChanged,
                filled: true,
                fillColor: const Color(0xffEDF2F9),
                hintStyle: Styles.txtG7Colors40014,
                prefixIcon: SvgPicture.asset(AssetConstants.ic_Search),
              ),
              Dimens.boxHeight12,
              // Status filter dropdown
              DroupDownButtonWigeat<String>(
                hintText: 'Select Status'.tr,
                items: _statusOptions,
                value: _selectedStatus.isEmpty ? null : _selectedStatus,
                isTitle: false,
                borderRadius: BorderRadius.circular(Dimens.twelve),
                onChanged: _onStatusChanged,
                textStyle: Styles.txtBlackColorW40014,
                hintStyle: Styles.txtG7Colors40014,
                isBorder: true,
              ),
              Dimens.boxHeight20,
            ],
          );

          // Empty state
          if (tickets.isEmpty) {
            return PullToRefreshWrapper(
              onRefresh: () => controller.fetchTicketsWithoutPagination(
                search: _searchController.text.trim(),
                status: (_selectedStatus.isEmpty || _selectedStatus == 'All') ? '' : _selectedStatus,
                showLoader: false,
              ),
              child: ListView(
                physics: kPullToRefreshScrollPhysics,
                padding: Dimens.edgeInsets20,
                children: [
                  filterSection,
                  Dimens.boxHeight20,
                  Center(child: Text('No tickets found', style: Styles.txtG7Colors40014)),
                  Dimens.boxHeight8,
                  Center(
                    child: Text(
                      'Create a new support ticket using the button below.',
                      style: Styles.txtG7Colors40014,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Dimens.boxHeight100,
                ],
              ),
            );
          }

          // Build ticket list
          final List<Widget> items = [
            filterSection,
            Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: Styles.txtBlackColorW70018,
            ),
            Dimens.boxHeight16,
          ];

          for (final t in tickets) {
            final Map<String, dynamic> ticket = Map<String, dynamic>.from(t);
            items.add(_buildTicketCard(ticket));
            items.add(Dimens.boxHeight16);
          }

          items.add(Dimens.boxHeight100);

          return PullToRefreshWrapper(
            onRefresh: () => controller.fetchTicketsWithoutPagination(
              search: _searchController.text.trim(),
              status: (_selectedStatus.isEmpty || _selectedStatus == 'All') ? '' : _selectedStatus,
              showLoader: false,
            ),
            child: ListView(
              physics: kPullToRefreshScrollPhysics,
              padding: Dimens.edgeInsets20,
              children: items,
            ),
          );
        },
      ),
    );
  }
}
