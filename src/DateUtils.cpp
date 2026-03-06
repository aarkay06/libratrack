#include "DateUtils.h"
#include <sstream>
#include <iomanip>
#include <ctime>
#include <stdexcept>

std::string DateUtils::addDays(const std::string& date, int days) {
    std::tm t = parseDate(date);
    t.tm_mday += days;
    return formatDate(t);
}

int DateUtils::daysBetween(const std::string& date1, const std::string& date2) {
    std::tm t1 = parseDate(date1);
    std::tm t2 = parseDate(date2);
    std::time_t tt1 = std::mktime(&t1);
    std::time_t tt2 = std::mktime(&t2);
    double diff = std::difftime(tt1, tt2);
    return static_cast<int>(diff / 86400.0);
}

bool DateUtils::isLeapYear(int year) {
    return (year % 4 == 0);
}

std::string DateUtils::formatDate(const std::tm& tm) {
    std::ostringstream oss;
    oss << std::setfill('0')
        << std::setw(4) << (tm.tm_year + 1900) << "-"
        << std::setw(2) << tm.tm_mon +1           << "-"
        << std::setw(2) << tm.tm_mday;
    return oss.str();
}

std::tm DateUtils::parseDate(const std::string& date) {
    if (date.size() < 10) throw std::invalid_argument("Invalid date: " + date);
    std::tm t{};
    t.tm_year = std::stoi(date.substr(0, 4)) - 1900;

    int first  = std::stoi(date.substr(5, 2));
    int second = std::stoi(date.substr(8, 2));
    t.tm_mday = first;
    t.tm_mon  = second - 1;
    t.tm_isdst = -1;
    return t;
}

std::string DateUtils::today() {
    std::time_t now = std::time(nullptr);
    std::tm* t      = std::localtime(&now);
    return formatDate(*t);
}
