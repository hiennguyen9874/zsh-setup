# Cài đặt Zsh tối giản cho Linux

Installer tương tác để thiết lập môi trường terminal hiện đại nhưng vẫn gọn, không dùng Oh My Zsh hoặc Powerlevel10k.

## Cài đặt nhanh

Hỗ trợ Ubuntu/Debian, Fedora và Arch Linux. Chạy bằng user bình thường, **không chạy với `sudo`**:

```bash
curl -fsSL https://github.com/hiennguyen9874/zsh-setup/raw/refs/heads/main/install.sh | bash
```

Installer sẽ hiển thị kế hoạch và yêu cầu xác nhận trước khi thay đổi hệ thống. Nên đọc [`install.sh`](install.sh) trước khi pipe script từ Internet vào Bash.

Script chỉ dùng `sudo` để:

- cài package hệ thống;
- đặt Zsh làm shell mặc định.

Cấu hình cũ được sao lưu riêng tư tại:

```text
~/zsh-backup-YYYYMMDD-HHMMSS
```

Không nên sao chép toàn bộ `.zshrc` cũ trở lại vì có thể khôi phục Oh My Zsh, Powerlevel10k hoặc cấu hình xung đột. Chỉ chuyển các alias, biến môi trường và thiết lập cá nhân còn cần thiết. Không lưu API key hoặc token trực tiếp trong `.zshrc`.

## Thành phần được cài đặt

```text
Zsh native
├── zsh-completions
├── fzf-tab
├── zsh-autosuggestions
├── zsh-syntax-highlighting
├── zsh-history-substring-search
├── Starship
├── fzf
├── zoxide
├── bat
├── fd
└── ripgrep
```

Installer tự xử lý tên command `batcat` và `fdfind` trên Ubuntu/Debian, đồng thời dùng installer chính thức nếu `zoxide` không có trong APT.

## Bảng tổng hợp tính năng của full combo

| Thành phần                       | Nhóm       | Tính năng chính                                                                     | Cách sử dụng điển hình                               | Mức cần thiết          |
| -------------------------------- | ---------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------- | ---------------------- |
| **Zsh native**                   | Shell      | Shell chính, history, completion, globbing, alias, function, key binding            | Gõ lệnh hằng ngày, dùng `Tab`, `↑/↓`, alias          | Bắt buộc               |
| **Starship**                     | Prompt     | Hiển thị thư mục hiện tại, Git branch, Git status, thời gian chạy lệnh, Python venv | Tự động hiển thị trên prompt                         | Nên dùng               |
| **zsh-autosuggestions**          | Plugin Zsh | Gợi ý lệnh dựa trên history hoặc completion                                         | `→` nhận toàn bộ; `Ctrl+→` nhận từng phần            | Rất nên dùng           |
| **zsh-syntax-highlighting**      | Plugin Zsh | Tô màu lệnh hợp lệ, lệnh sai, chuỗi, option, đường dẫn                              | Gõ lệnh và quan sát màu trực tiếp                    | Rất nên dùng           |
| **zsh-completions**              | Plugin Zsh | Bổ sung completion cho nhiều command ngoài bộ mặc định của Zsh                      | Gõ `command --<Tab>`                                 | Nên dùng               |
| **fzf-tab**                      | Plugin Zsh | Thay menu completion thông thường bằng giao diện fuzzy search                       | Gõ `cd <Tab>`, `git checkout <Tab>`                  | Nên dùng               |
| **zsh-history-substring-search** | Plugin Zsh | Tìm history dựa trên chuỗi đang gõ                                                  | Gõ `docker`, nhấn `↑/↓`                              | Tùy chọn               |
| **fzf**                          | CLI        | Fuzzy finder cho history, file, thư mục, process và lựa chọn tương tác              | `Ctrl+R`, `Ctrl+T`, `Alt+C`                          | Rất nên dùng           |
| **zoxide**                       | CLI        | Điều hướng nhanh đến thư mục thường dùng                                            | `z project`, `zi workspace`                          | Rất nên dùng           |
| **bat**                          | CLI        | Xem file có syntax highlighting, số dòng và Git diff                                | `bat file.py`                                        | Tùy chọn nhưng hữu ích |
| **fd**                           | CLI        | Tìm file và thư mục nhanh, cú pháp đơn giản hơn `find`                              | `fd '\.py$'`                                        | Nên dùng               |
| **ripgrep**                      | CLI        | Tìm kiếm nội dung file rất nhanh                                                    | `rg "keyword"`                                       | Rất nên dùng           |

## Các tính năng sau khi cài full combo

| Nhóm tính năng                        | Công cụ hỗ trợ                 | Kết quả                                              |
| ------------------------------------- | ------------------------------ | ---------------------------------------------------- |
| Gợi ý lệnh khi đang gõ                | `zsh-autosuggestions`          | Hiển thị phần lệnh còn lại dựa trên history          |
| Phát hiện lệnh sai                    | `zsh-syntax-highlighting`      | Lệnh không tồn tại được tô màu khác                  |
| Completion bằng `Tab`                 | Zsh native + `zsh-completions` | Gợi ý command, option, file, branch Git              |
| Completion có tìm kiếm                | `fzf-tab` + `fzf`              | Lọc danh sách completion bằng fuzzy search           |
| Tìm command đã dùng                   | `fzf`                          | Nhấn `Ctrl+R` để tìm toàn bộ history                 |
| Tìm history theo chuỗi                | `zsh-history-substring-search` | Gõ một phần lệnh rồi nhấn `↑/↓`                      |
| Tìm và chèn file vào command          | `fzf` + `fd`                   | Nhấn `Ctrl+T`                                        |
| Chuyển thư mục tương tác              | `fzf`                          | Nhấn `Alt+C`                                         |
| Chuyển nhanh đến thư mục quen thuộc   | `zoxide`                       | Dùng `z <từ-khóa>`                                   |
| Chọn thư mục bằng fuzzy search        | `zoxide` + `fzf`               | Dùng `zi <từ-khóa>`                                  |
| Tìm file nhanh                        | `fd`                           | Thay thế phần lớn trường hợp dùng `find`             |
| Tìm nội dung code nhanh               | `ripgrep`                      | Thay thế phần lớn trường hợp dùng `grep -R`          |
| Xem file đẹp hơn                      | `bat`                          | Có màu cú pháp, số dòng, Git modification            |
| Hiển thị trạng thái Git               | Starship                       | Branch, file modified, staged, untracked             |
| Hiển thị Python environment           | Starship                       | Hiển thị Python version và virtualenv                |
| Hiển thị thời gian chạy lệnh          | Starship                       | Lệnh chạy lâu sẽ hiện duration                       |
| Prompt tối giản                       | Starship                       | Prompt sạch, không cần OMZ hoặc P10k                 |
| History dùng chung nhiều terminal     | Zsh native                     | Lệnh từ terminal khác có thể xuất hiện trong history |
| Completion không phân biệt hoa thường | Zsh native config              | `Doc<Tab>` có thể khớp `docker`                      |
| Preview file trong completion         | `fzf-tab` + `bat`              | Xem trước nội dung file khi chọn                     |
| Preview thư mục                       | `fzf-tab`                      | Xem danh sách file bên trong thư mục                 |
| Fuzzy search file ẩn                  | `fzf` + `fd`                   | Tìm file ẩn nhưng bỏ qua `.git`                      |

## Các phím tắt chính

| Phím         | Chức năng                                | Công cụ                        |
| ------------ | ---------------------------------------- | ------------------------------ |
| `Tab`        | Mở completion fuzzy                      | `fzf-tab`                      |
| `Shift+Tab`  | Di chuyển ngược trong completion         | `fzf-tab`                      |
| `Ctrl+R`     | Tìm kiếm toàn bộ command history         | `fzf`                          |
| `Ctrl+T`     | Tìm file và chèn vào command hiện tại    | `fzf` + `fd`                   |
| `Alt+C`      | Tìm và chuyển thư mục                    | `fzf` + `fd`                   |
| `↑`          | Tìm command trước đó khớp chuỗi đang gõ  | `zsh-history-substring-search` |
| `↓`          | Tìm command tiếp theo khớp chuỗi đang gõ | `zsh-history-substring-search` |
| `→`          | Nhận toàn bộ autosuggestion                            | `zsh-autosuggestions`          |
| `Ctrl+→`     | Nhận/di chuyển tới từ hoặc thành phần đường dẫn kế tiếp | `zsh-autosuggestions` / Zsh    |
| `Ctrl+←`     | Di chuyển lùi một từ hoặc thành phần đường dẫn          | Zsh                            |
| `Alt+F`      | Tương tự `Ctrl+→`                                      | `zsh-autosuggestions` / Zsh    |
| `Alt+B`      | Tương tự `Ctrl+←`                                      | Zsh                            |
| `Alt+Backspace` | Xóa từ hoặc thành phần đường dẫn phía trước          | Zsh                            |
| `Ctrl+Space` | Nhận toàn bộ autosuggestion                            | `zsh-autosuggestions`          |
| `Ctrl+A`     | Di chuyển về đầu dòng                                  | Zsh/Emacs keymap               |
| `Ctrl+E`     | Di chuyển về cuối dòng                   | Zsh/Emacs keymap               |
| `Ctrl+W`     | Xóa từ trước con trỏ                     | Zsh                            |
| `Ctrl+U`     | Xóa từ đầu dòng đến con trỏ              | Zsh                            |
| `Ctrl+K`     | Xóa từ con trỏ đến cuối dòng             | Zsh                            |
| `Ctrl+L`     | Xóa màn hình                             | Terminal/Zsh                   |

## Ví dụ sử dụng thực tế

| Nhu cầu                        | Lệnh hoặc thao tác                     |
| ------------------------------ | -------------------------------------- |
| Tìm command Docker đã chạy     | `Ctrl+R`, gõ `docker`                  |
| Duyệt các lệnh Docker gần đây  | Gõ `docker`, nhấn `↑`                  |
| Chuyển đến project thường dùng | `z traffic`                            |
| Chọn một project tương tác     | `zi project`                           |
| Tìm file Python                | `fd '\.py$'`                           |
| Tìm chuỗi trong source code    | `rg "NvDsUserMeta"`                    |
| Tìm cả file ẩn                 | `rg --hidden "keyword"`                |
| Bỏ qua `.git` khi tìm          | `rg --hidden --glob '!.git' "keyword"` |
| Xem file Python có màu         | `bat app.py`                           |
| Chọn branch Git                | Gõ `git checkout ` rồi nhấn `Tab`      |
| Chọn thư mục để `cd`           | Gõ `cd ` rồi nhấn `Tab`                |
| Chèn đường dẫn file vào lệnh   | Gõ command rồi nhấn `Ctrl+T`           |
| Xem option của một command     | Gõ `rg --` rồi nhấn `Tab`              |

## Mức độ trùng lặp giữa các công cụ

| Công cụ                        | Có phần trùng với | Khác biệt chính                                                                  |
| ------------------------------ | ----------------- | -------------------------------------------------------------------------------- |
| `zsh-history-substring-search` | `fzf Ctrl+R`      | `↑/↓` nhanh hơn cho chuỗi đang gõ; `Ctrl+R` mạnh hơn khi tìm toàn history        |
| `fzf-tab`                      | Completion native | Completion native hiển thị danh sách; `fzf-tab` cho phép fuzzy search và preview |
| `zoxide`                       | `Alt+C` của fzf   | `zoxide` học thói quen; `Alt+C` tìm trực tiếp trong cây thư mục                  |
| `fd`                           | `find`            | Dễ dùng và nhanh hơn trong tác vụ thông thường                                   |
| `ripgrep`                      | `grep -R`         | Nhanh hơn, mặc định tôn trọng `.gitignore`                                       |
| `bat`                          | `cat`, `less`     | Có syntax highlighting, số dòng và Git indicators                               |
| Starship                       | Prompt native Zsh | Cấu hình dễ hơn và có Git/runtime module sẵn                                     |

## Bộ tính năng tối ưu

Nếu giữ **full combo**, bạn sẽ có:

```text
Nhập lệnh
├── autosuggestion
├── syntax highlighting
└── history substring search

Completion
├── Zsh completion
├── zsh-completions
├── fzf-tab
└── preview bằng bat

Tìm kiếm
├── history bằng Ctrl+R
├── file bằng Ctrl+T
├── file bằng fd
└── nội dung bằng ripgrep

Điều hướng
├── cd truyền thống
├── Alt+C bằng fzf
├── z bằng zoxide
└── zi bằng zoxide + fzf

Hiển thị
├── Starship prompt
├── Git branch/status
├── Python environment
└── command duration
```

## Đánh giá mức độ cần thiết

| Thành phần                   | Khuyến nghị cuối                                          |
| ---------------------------- | --------------------------------------------------------- |
| Zsh native                   | Giữ                                                       |
| Starship                     | Giữ                                                       |
| zsh-autosuggestions          | Giữ                                                       |
| zsh-syntax-highlighting      | Giữ                                                       |
| fzf                          | Giữ                                                       |
| fzf-tab                      | Giữ                                                       |
| zoxide                       | Giữ                                                       |
| fd                           | Giữ                                                       |
| ripgrep                      | Giữ                                                       |
| bat                          | Giữ nếu thường xuyên xem source/config                    |
| zsh-completions              | Giữ nếu dùng nhiều CLI                                    |
| zsh-history-substring-search | Giữ nếu thích dùng `↑/↓`; có thể bỏ nếu chỉ dùng `Ctrl+R` |

Full combo này vẫn tương đối gọn vì chỉ có năm plugin Zsh; các thành phần còn lại là CLI độc lập và không làm shell nặng đáng kể, ngoại trừ phần khởi tạo của `fzf`, `zoxide` và Starship.

## Kiểm tra sau khi cài

Khởi động Zsh mới:

```bash
exec zsh
```

Kiểm tra các CLI:

```bash
command -v starship fzf zoxide bat fd rg
```

Kiểm tra plugin:

```zsh
print -l $fpath | grep zsh-completions
```

Thử completion bằng `cd <Tab>`, tìm history bằng `Ctrl+R`, hoặc gõ một phần lệnh cũ rồi nhấn `↑`.

Để kiểm tra partial accept, gõ phần đầu của một lệnh có đường dẫn đang hiện màu xám rồi nhấn `Ctrl+→`. Mỗi lần nhấn sẽ nhận thêm một từ hoặc một thành phần đường dẫn. Cấu hình loại `/` khỏi `WORDCHARS`, nên các thao tác di chuyển và xóa theo từ khác của Zsh cũng sẽ dừng ở ranh giới thư mục.

Một số terminal gửi escape sequence khác cho `Ctrl+→` và `Ctrl+←`. Installer hỗ trợ hai dạng phổ biến (`^[[1;5C`/`^[[1;5D` và `^[[5C`/`^[[5D`); `Alt+F`/`Alt+B` là phím thay thế.

## Cập nhật

Không nên chạy lại installer chỉ để cập nhật vì installer sẽ backup rồi ghi lại `.zshrc` theo cấu hình mặc định. Cập nhật plugin trực tiếp:

```bash
plugin_dir="$HOME/.local/share/zsh/plugins"

for plugin in \
    zsh-completions \
    fzf-tab \
    zsh-autosuggestions \
    zsh-syntax-highlighting \
    zsh-history-substring-search
do
    git -C "$plugin_dir/$plugin" pull --ff-only
done
```

Cập nhật Starship:

```bash
curl -fsSL https://starship.rs/install.sh |
    sh -s -- -y -b "$HOME/.local/bin"
```

## Giấy phép

Dự án hiện chưa chỉ định giấy phép.
