#include "mainwindow.h"
#include <QApplication>

int main(int argc, char *argv[]) {

	// determine the startup config file...
	const char *config_file = nullptr;
	bool start_minimized = false;
	for (int k = 1; k < argc; k++) {
		std::string arg(argv[k]);
		if (arg == "-c" || arg == "--config")
			config_file = argv[k + 1];
		if (arg == "--minimized")
			start_minimized = true;
	}

	QApplication a(argc, argv);
	MainWindow w(nullptr, config_file);
	if (start_minimized)
		w.showMinimized();
	else
		w.show();
	return a.exec();
}
