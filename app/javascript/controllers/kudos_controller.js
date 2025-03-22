import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button"]

    connect() {
        console.log("Kudos controller connected")
    }

    giveKudos(event) {
        event.preventDefault()

        const button = event.currentTarget
        const url = button.getAttribute("href")

        fetch(url, {
            method: "POST",
            headers: {
                "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content,
                "Accept": "application/json"
            }
        })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    // Replace the button with the kudos count
                    const container = button.closest(".activity-actions")

                    const kudosEl = document.createElement("span")
                    kudosEl.classList.add("kudos-given")
                    kudosEl.innerHTML = `<i class="kudos-icon">👏</i> ${data.kudos_count}`

                    container.innerHTML = ""
                    container.appendChild(kudosEl)
                } else {
                    console.error("Error giving kudos:", data.error)
                }
            })
            .catch(error => {
                console.error("Error giving kudos:", error)
            })
    }
}