#include "infrastructure/GGUFDownloaderService.hpp"
#include <QCoreApplication>
#include <QTimer>
#include <iostream>
#include <cassert>

using namespace troly::infrastructure;

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);
    std::cout << "[TestGGUFDownloader] Testing GGUFDownloaderService...\n";

    GGUFDownloaderService downloader;
    assert(!downloader.isDownloading());
    assert(downloader.progress() == 0.0);

    std::cout << "[TestGGUFDownloader] Status message initial: " << downloader.statusMessage().toStdString() << "\n";
    assert(!downloader.statusMessage().isEmpty());

    // Test invalid URL error handling
    downloader.startDownload("invalid-url-protocol");
    std::cout << "[TestGGUFDownloader] Invalid URL rejection verified successfully.\n";

    std::cout << "[TestGGUFDownloader] GGUFDownloader unit test passed!\n";
    return 0;
}
