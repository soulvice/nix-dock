#!/usr/bin/env python3

import subprocess
import json
import sys
from http.server import HTTPServer, BaseHTTPRequestHandler
import logging
from urllib.parse import urlparse

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

class SwarmTokenHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        """Override to use our logger"""
        logger.info(format % args)

    def do_GET(self):
        """Handle GET requests"""
        parsed_path = urlparse(self.path)
        path = parsed_path.path

        try:
            if path == '/health':
                self.handle_health()
            elif path == '/swarm/worker':
                self.handle_worker_token()
            elif path == '/swarm/manager':
                self.handle_manager_token()
            else:
                self.send_error(404, "Not Found")
        except Exception as e:
            logger.error(f"Error handling request {path}: {e}")
            self.send_error(500, "Internal Server Error")

    def handle_health(self):
        """Health check endpoint"""
        try:
            # Check if Docker is running and swarm is active
            result = subprocess.run(['docker', 'info', '--format', '{{.Swarm.LocalNodeState}}'],
                                  capture_output=True, text=True, timeout=5)

            if result.returncode == 0 and result.stdout.strip() == 'active':
                self.send_json_response({'status': 'healthy', 'swarm': 'active'})
            else:
                self.send_json_response({'status': 'unhealthy', 'swarm': 'inactive'}, status=503)

        except subprocess.TimeoutExpired:
            self.send_json_response({'status': 'unhealthy', 'error': 'docker timeout'}, status=503)
        except Exception as e:
            logger.error(f"Health check failed: {e}")
            self.send_json_response({'status': 'unhealthy', 'error': str(e)}, status=503)

    def handle_worker_token(self):
        """Get worker join token"""
        try:
            result = subprocess.run(['docker', 'swarm', 'join-token', 'worker', '-q'],
                                  capture_output=True, text=True, timeout=10)

            if result.returncode == 0:
                token = result.stdout.strip()
                self.send_json_response({'token': token, 'type': 'worker'})
            else:
                logger.error(f"Failed to get worker token: {result.stderr}")
                self.send_json_response({'error': 'Failed to get worker token'}, status=500)

        except subprocess.TimeoutExpired:
            self.send_json_response({'error': 'Docker command timeout'}, status=500)
        except Exception as e:
            logger.error(f"Worker token error: {e}")
            self.send_json_response({'error': str(e)}, status=500)

    def handle_manager_token(self):
        """Get manager join token"""
        try:
            result = subprocess.run(['docker', 'swarm', 'join-token', 'manager', '-q'],
                                  capture_output=True, text=True, timeout=10)

            if result.returncode == 0:
                token = result.stdout.strip()
                self.send_json_response({'token': token, 'type': 'manager'})
            else:
                logger.error(f"Failed to get manager token: {result.stderr}")
                self.send_json_response({'error': 'Failed to get manager token'}, status=500)

        except subprocess.TimeoutExpired:
            self.send_json_response({'error': 'Docker command timeout'}, status=500)
        except Exception as e:
            logger.error(f"Manager token error: {e}")
            self.send_json_response({'error': str(e)}, status=500)

    def send_json_response(self, data, status=200):
        """Send JSON response"""
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        response = json.dumps(data, indent=2)
        self.wfile.write(response.encode('utf-8'))

def main():
    """Main server function"""
    # Get configuration from environment or use defaults
    import os
    host = os.environ.get('SWARM_TOKEN_HOST', '0.0.0.0')
    port = int(os.environ.get('SWARM_TOKEN_PORT', '3535'))

    logger.info(f"Starting Swarm Token Server on {host}:{port}")

    # Create and start server
    server_address = (host, port)
    httpd = HTTPServer(server_address, SwarmTokenHandler)

    try:
        logger.info(f"Server running at http://{host}:{port}/")
        logger.info("Available endpoints:")
        logger.info("  GET /health - Health check")
        logger.info("  GET /swarm/worker - Get worker join token")
        logger.info("  GET /swarm/manager - Get manager join token")
        httpd.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down server...")
        httpd.server_close()
    except Exception as e:
        logger.error(f"Server error: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()