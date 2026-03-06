#include "SearchEngine.h"
#include <algorithm>
#include <cctype>
#include <cmath>

SearchEngine::SearchEngine(std::vector<Book>& catalog)
    : catalog_(catalog)
{}

double SearchEngine::similarity(const std::string& a, const std::string& b) const {
    if (a.empty() && b.empty()) return 1.0;
    if (a.empty() || b.empty()) return 0.0;

    const size_t la = a.size(), lb = b.size();
    std::vector<std::vector<int>> dp(la + 1, std::vector<int>(lb + 1, 0));
    for (size_t i = 0; i <= la; ++i) dp[i][0] = static_cast<int>(i);
    for (size_t j = 0; j <= lb; ++j) dp[0][j] = static_cast<int>(j);
    for (size_t i = 1; i <= la; ++i)
        for (size_t j = 1; j <= lb; ++j) {
            int cost = (std::tolower(a[i-1]) == std::tolower(b[j-1])) ? 0 : 1;
            dp[i][j] = std::min({ dp[i-1][j] + 1,
                                  dp[i][j-1] + 1,
                                  dp[i-1][j-1] + cost });
        }
    int dist = dp[la][lb];
    return 1.0 - static_cast<double>(dist) / static_cast<double>(std::max(la, lb));
}

std::vector<SearchResult> SearchEngine::fuzzyMatch(const std::string& query) const {
    std::vector<SearchResult> results;
    for (auto& book : catalog_) {
        double score = similarity(query, book.getTitle());
        if (score >= 0.7) {
            results.push_back({const_cast<Book*>(&book), score});
        }
    }
    return results;
}

std::vector<Book*> SearchEngine::searchByAuthor(const std::string& query) const {
    std::vector<Book*> results;
    std::string q = query;
    std::transform(q.begin(), q.end(), q.begin(), ::tolower);

    for (auto& book : catalog_) {
        std::string author = book.getAuthor();
        std::transform(author.begin(), author.end(), author.begin(), ::tolower);

        std::string last_word;
        size_t pos = author.rfind(' ');
        if (pos != std::string::npos)
            last_word = author.substr(pos + 1);
        else
            last_word = author;

        if (last_word.find(q) != std::string::npos) {
            results.push_back(const_cast<Book*>(&book));
        }
    }
    return results;
}

std::vector<Book*> SearchEngine::filterByGenre(const std::string& genre) const {
    std::vector<Book*> results;
    for (auto& book : catalog_) {
        if (book.getGenre() == genre) {
            results.push_back(const_cast<Book*>(&book));
        }
    }
    return results;
}

std::vector<Book*> SearchEngine::searchByYearRange(int from, int to) const {
    std::vector<Book*> results;
    for (auto& book : catalog_) {
        int year = book.getPublicationYear();
        if (year > from && year < to) {
            results.push_back(const_cast<Book*>(&book));
        }
    }
    return results;
}

std::vector<SearchResult> SearchEngine::rankResults(
    std::vector<SearchResult> results) const
{
    std::sort(results.begin(), results.end(),
        [](const SearchResult& a, const SearchResult& b) {
            return a.score < b.score;
        });
    return results;
}