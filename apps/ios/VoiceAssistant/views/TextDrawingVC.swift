import UIKit

enum Mode {
    case draw
    case erase
}

class TextDrawingVC: UIViewController {
    @IBOutlet weak var drawButton: UIBarButtonItem!
    @IBOutlet weak var eraseButton: UIBarButtonItem!
    @IBOutlet weak var textDrawingView: TextDrawingView!

    private var _mode: Mode = .draw

    override func viewDidLoad() {
        super.viewDidLoad()
        self._setMode(.draw)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @IBAction func onDrawButtonClicked(_ sender: Any) {
        self._setMode(.draw)
    }

    @IBAction func onEraseButtonClicked(_ sender: Any) {
        self._setMode(.erase)
    }

    @IBAction func onConfirmButtonClicked(_ sender: Any) {
        DispatchQueue.main.async {
            let renderer = UIGraphicsImageRenderer(bounds: self.view.bounds)
            let image = renderer.image { rendererContext in
                self.textDrawingView.layer.render(in: rendererContext.cgContext)
            }
            
            if let image = image.toSquareImage(format: .png, size: IMAGE_SIZE) {
                MediaManager.shared.setImageList([image])
            }
            self.navigationController?.popViewController(animated: true)
        }
    }

    private func _setMode(_ mode: Mode) {
        self._mode = mode
        
        switch mode {
        case .draw:
            self.drawButton.tintColor = .systemBlue
            self.eraseButton.tintColor = .gray
        case .erase:
            self.drawButton.tintColor = .gray
            self.eraseButton.tintColor = .systemBlue
        }
    }
}

class TextDrawingView: UIView {
    var lines = [[CGPoint]]()
    var currentLine: [CGPoint] = []

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }

        context.setLineWidth(5.0) // Adjust line width as needed
        context.setStrokeColor(UIColor.black.cgColor)

        // Draw all completed lines
        for line in lines {
            context.move(to: line[0])
            for i in 1..<line.count {
                context.addLine(to: line[i])
            }
            context.strokePath()
        }

        // Draw the current line (while drawing)
        if !currentLine.isEmpty {
            context.move(to: currentLine[0])
            for i in 1..<currentLine.count {
                context.addLine(to: currentLine[i])
            }
            context.strokePath()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentLine = [touch.location(in: self)]
        setNeedsDisplay() // Important: Call setNeedsDisplay() here
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        currentLine.append(touch.location(in: self))
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lines.append(currentLine)
        currentLine = []
        setNeedsDisplay()
    }
}
