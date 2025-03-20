class WakatimeMirror < ApplicationRecord
  belongs_to :user

  encrypts :api_key

  scope :active, -> { where(deleted_at: nil) }
  validates :api_url, uniqueness: { scope: :user_id, allow_nil: true, conditions: -> { active } }

  validates :api_url, format: { with: URI.regexp }, if: -> { api_url.present? }

  def sync_heartbeats(heartbeats)
    # do in batches of 100
    heartbeats.each_slice(100) do |slice|
      url = "#{api_url}/api/v1/heartbeats.bulk"
      headers = {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Authorization" => "Basic #{Base64.strict_encode64("#{api_key}:")}",
        "User-Agent" => "Hackatime/#{Hackatime::Application::VERSION}",
        "X-Origin" => "Hackatime/#{Hackatime::Application::VERSION}",
        "X-Origin-Instance" => "Hackatime/#{Hackatime::Application::VERSION}"
      }

      HTTP.post(url, headers: headers, json: { heartbeats: slice })
    end
  end
end


# func (m *WakatimeRelayMiddleware) ServeHTTP(w http.ResponseWriter, r *http.Request, next http.HandlerFunc) {
# 	defer next(w, r)

# 	ownInstanceId := config.Get().InstanceId
# 	originInstanceId := r.Header.Get("X-Origin-Instance")

# 	if r.Method != http.MethodPost || originInstanceId == ownInstanceId {
# 		return
# 	}

# 	user := middlewares.GetPrincipal(r)
# 	if user == nil || user.WakatimeApiKey == "" {
# 		return
# 	}

# 	err := m.filterByCache(r)
# 	if err != nil {
# 		slog.Warn("filter cache error", "error", err)
# 		return
# 	}

# 	body, _ := io.ReadAll(r.Body)
# 	r.Body.Close()
# 	r.Body = io.NopCloser(bytes.NewBuffer(body))

# 	// prevent cycles
# 	downstreamInstanceId := ownInstanceId
# 	if originInstanceId != "" {
# 		downstreamInstanceId = originInstanceId
# 	}

# 	headers := http.Header{
# 		"X-Machine-Name": r.Header.Values("X-Machine-Name"),
# 		"Content-Type":   r.Header.Values("Content-Type"),
# 		"Accept":         r.Header.Values("Accept"),
# 		"User-Agent":     r.Header.Values("User-Agent"),
# 		"X-Origin": []string{
# 			fmt.Sprintf("wakapi v%s", config.Get().Version),
# 		},
# 		"X-Origin-Instance": []string{downstreamInstanceId},
# 		"Authorization": []string{
# 			fmt.Sprintf("Basic %s", base64.StdEncoding.EncodeToString([]byte(user.WakatimeApiKey))),
# 		},
# 	}

# 	url := user.WakaTimeURL(config.WakatimeApiUrl) + config.WakatimeApiHeartbeatsBulkUrl

# 	go m.send(
# 		http.MethodPost,
# 		url,
# 		bytes.NewReader(body),
# 		headers,
# 		user,
# 	)
# }
