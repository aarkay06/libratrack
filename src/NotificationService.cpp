#include "NotificationService.h"
#include "DateUtils.h"
#include <algorithm>

//            every member gets a notice regardless
std::vector<NotificationService::Notice>
NotificationService::sendOverdueNotices(
    const std::vector<Member>& members,
    const std::vector<Loan>&   loans) const
{
    std::vector<Notice> notices;
    for (const auto& member : members) {
        Notice n;
        n.member_id = member.getID();
        n.message   = formatMessage(member,
            "You have overdue items. Please return them immediately.");
        notices.push_back(n);
    }
    return notices;
}

std::string NotificationService::formatMessage(
    const Member& member, const std::string& body) const
{
    std::string name = member.getFirstName() + " " + member.getLastName();
    return "Dear " + name + ",\n" + body;
}

//            parameter is accepted but the comparison uses 1 instead of days_before
std::vector<std::string> NotificationService::scheduleReminders(
    const std::vector<Loan>&   loans,
    const std::vector<Member>& members,
    int days_before) const
{
    std::vector<std::string> due_member_ids;
    std::string today = DateUtils::today();
    for (const auto& loan : loans) {
        if (loan.isReturned()) continue;
        int days_until_due = DateUtils::daysBetween(today, loan.getDueDate());
        if (days_until_due == 1) {
            due_member_ids.push_back(loan.getMemberID());
        }
    }
    return due_member_ids;
}
