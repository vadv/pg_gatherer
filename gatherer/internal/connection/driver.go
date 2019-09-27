package connection

import (
	"database/sql"
	"database/sql/driver"
	"net"
	"time"

	"github.com/lib/pq"
)

// original: https://gist.github.com/tejasmanohar/fdaafe17d7ac1c083147055f2c03959b

// KeepAliveDuration is the duration between keepalives for all new Postgres connections.
var KeepAliveDuration = 5 * time.Second

func init() {
	sql.Register("gatherer-pq", &enhancedDriver{})
}

// enhancedDriver is a wrapper over lib/pq to mimic jackc/pgx's keepalive policy.
// This avoids:
// * an issue with connections leak
// * an issue where the NAT kills an "idle" connection while it is waiting on a long-running query.
type enhancedDriver struct{}
type dialer struct{}

// Open returns a new SQL driver connection with our custom settings.
func (d *enhancedDriver) Open(name string) (driver.Conn, error) {
	return pq.DialOpen(&dialer{}, name)
}

// Dial returns network connection
func (d dialer) Dial(ntw, addr string) (net.Conn, error) {
	customDialer := net.Dialer{KeepAlive: KeepAliveDuration}
	return customDialer.Dial(ntw, addr)
}

// DialTimeout returns network connection
func (d dialer) DialTimeout(ntw, addr string, timeout time.Duration) (net.Conn, error) {
	customDialer := net.Dialer{Timeout: timeout, KeepAlive: KeepAliveDuration}
	return customDialer.Dial(ntw, addr)
}
