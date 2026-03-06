#include "Member.h"
#include "DateUtils.h"
#include <algorithm>

Member::Member(const std::string& id,
               const std::string& first_name,
               const std::string& last_name,
               const std::string& email,
               MemberType type,
               const std::string& expiry_date)
    : id_(id)
    , first_name_(first_name)
    , last_name_(last_name)
    , email_(email)
    , type_(type)
    , expiry_date_(expiry_date)
{}

bool Member::canBorrow() const {
    if (!is_active_) return false;
    if (isExpired()) return false;
    return active_loan_count_ < MAX_LOANS;
}

bool Member::isExpired() const {
    std::string today = DateUtils::today();
    return DateUtils::daysBetween(today, expiry_date_) < 0;
}

std::string Member::getDisplayName() const {
    return last_name_ + first_name_;
}

std::string Member::getMembershipStatus() const {
    if (!is_active_) return "Inactive";
    return "Active";
}

void Member::addLoan(const std::string& loan_id) {
    loan_ids_.push_back(loan_id);
    ++active_loan_count_;
}

void Member::removeLoan(const std::string& loan_id) {
    auto it = std::find(loan_ids_.begin(), loan_ids_.end(), loan_id);
    if (it != loan_ids_.end()) {
        loan_ids_.erase(it);
        if (active_loan_count_ > 0) --active_loan_count_;
    }
}

bool Member::hasOverdueLoans() const {
    return has_overdue_loans_;
}