#pragma once

#include <cstdint>

#include <QtNetwork/QTcpServer>
#include <QtNetwork/QTcpSocket>
#include <QDataStream>
#include <qregularexpression.h>

class RemoteControlSocket : public QObject {
	Q_OBJECT
	QTcpServer server;
	QList<QTcpSocket*> clients;
	bool listening_ = false;
public:
	RemoteControlSocket(uint16_t port);
	bool isListening() const { return listening_; }

signals:
	void refresh_streams();
	void start();
	void stop();
	void filename(QString s);
	void recordingPathQuery(QTcpSocket *sock);
	void select_all();
	void select_none();

public slots:
	void addClient();
	void handleLine(QString s, QTcpSocket* sock);
};
