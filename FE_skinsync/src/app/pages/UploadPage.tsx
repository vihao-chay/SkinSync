import { useState } from "react";
import { Link, useNavigate } from "react-router";
import { ArrowLeft, Camera, Upload, X } from "lucide-react";

export function UploadPage() {
  const navigate = useNavigate();
  const [uploadedImage, setUploadedImage] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const reader = new FileReader();
      reader.onload = (e) => {
        setUploadedImage(e.target?.result as string);
      };
      reader.readAsDataURL(file);
    }
  };
  
  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };
  
  const handleDragLeave = () => {
    setIsDragging(false);
  };
  
  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);
    const file = e.dataTransfer.files?.[0];
    if (file && file.type.startsWith('image/')) {
      const reader = new FileReader();
      reader.onload = (e) => {
        setUploadedImage(e.target?.result as string);
      };
      reader.readAsDataURL(file);
    }
  };
  
  const handleNext = () => {
    // Simulate analysis
    setTimeout(() => {
      navigate("/dashboard");
    }, 1000);
  };
  
  const handleSkip = () => {
    navigate("/dashboard");
  };
  
  return (
    <div className="min-h-screen bg-gradient-to-b from-white to-[#faf9f6] pt-24 pb-12 px-6">
      <div className="max-w-3xl mx-auto">
        {/* Header */}
        <div className="mb-8">
          <Link to="/quiz" className="inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition-colors mb-4">
            <ArrowLeft className="w-4 h-4" />
            Trở Lại
          </Link>
          
          {/* Progress Bar */}
          <div className="relative h-2 bg-secondary rounded-full overflow-hidden mb-4">
            <div 
              className="absolute inset-y-0 left-0 bg-gradient-to-r from-[#c4a882] to-[#8c6e52] transition-all duration-500"
              style={{ width: '40%' }}
            />
          </div>
          <p className="text-sm text-muted-foreground">Bước 2 / 5</p>
        </div>
        
        {/* Content */}
        <div className="bg-white rounded-3xl shadow-xl p-8 md:p-12 border border-border">
          <h1 className="text-4xl font-bold mb-3">
            Tải Ảnh <span className="text-[#c4a882]">Da Mặt</span>
            <span className="text-lg text-muted-foreground ml-3">(Tùy Chọn)</span>
          </h1>
          <p className="text-muted-foreground mb-12">
            Ảnh chụp rõ nét giúp AI phân tích chính xác nhất. Đảm bảo mặt bạn được chiếu sáng tốt.
          </p>
          
          {/* Upload Area */}
          {!uploadedImage ? (
            <div
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              className={`relative border-2 border-dashed rounded-3xl p-12 text-center transition-all ${
                isDragging
                  ? "border-[#c4a882] bg-gradient-to-br from-[#c4a882]/5 to-[#8c6e52]/5"
                  : "border-border hover:border-[#c4a882]/30"
              }`}
            >
              <div className="w-20 h-20 mx-auto mb-6 rounded-full bg-gradient-to-br from-[#d4f4f4] to-[#fce7f3] flex items-center justify-center">
                <Camera className="w-10 h-10 text-[#c4a882]" />
              </div>
              
              <h3 className="text-xl font-semibold mb-2">Kéo thả ảnh vào đây</h3>
              <p className="text-muted-foreground mb-6">hoặc</p>
              
              <label className="inline-block px-6 py-3 bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white rounded-full cursor-pointer hover:shadow-lg transition-all">
                <span className="flex items-center gap-2">
                  <Upload className="w-4 h-4" />
                  Chọn Ảnh
                </span>
                <input
                  type="file"
                  accept="image/*"
                  onChange={handleFileChange}
                  className="hidden"
                />
              </label>
              
              <p className="text-sm text-muted-foreground mt-6">
                Hỗ trợ: JPG, PNG, HEIC (Tối đa 10MB)
              </p>
            </div>
          ) : (
            <div className="relative">
              <div className="relative rounded-3xl overflow-hidden border-2 border-[#c4a882] mb-6">
                <img 
                  src={uploadedImage} 
                  alt="Uploaded face"
                  className="w-full h-96 object-cover"
                />
                <button
                  onClick={() => setUploadedImage(null)}
                  className="absolute top-4 right-4 w-10 h-10 bg-white/90 backdrop-blur-sm rounded-full flex items-center justify-center hover:bg-white transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
                
                {/* Scan Effect */}
                <div className="absolute inset-0 border-2 border-[#c4a882]/50">
                  <div className="absolute top-1/4 left-1/4 w-6 h-6 border-t-2 border-l-2 border-[#c4a882]" />
                  <div className="absolute top-1/4 right-1/4 w-6 h-6 border-t-2 border-r-2 border-[#c4a882]" />
                  <div className="absolute bottom-1/4 left-1/4 w-6 h-6 border-b-2 border-l-2 border-[#c4a882]" />
                  <div className="absolute bottom-1/4 right-1/4 w-6 h-6 border-b-2 border-r-2 border-[#c4a882]" />
                </div>
              </div>
              
              <div className="bg-gradient-to-r from-[#d4f4f4] to-[#fce7f3] rounded-2xl p-4 mb-8">
                <p className="text-sm text-center">
                  ✓ Ảnh của bạn đã sẵn sàng cho phân tích AI
                </p>
              </div>
            </div>
          )}
          
          {/* Tips */}
          <div className="grid md:grid-cols-3 gap-4 my-8 p-6 bg-muted/30 rounded-2xl">
            <div className="text-center">
              <div className="text-2xl mb-2">💡</div>
              <p className="text-sm text-muted-foreground">Chụp trong ánh sáng tự nhiên</p>
            </div>
            <div className="text-center">
              <div className="text-2xl mb-2">👤</div>
              <p className="text-sm text-muted-foreground">Mặt nhìn thẳng vào camera</p>
            </div>
            <div className="text-center">
              <div className="text-2xl mb-2">✨</div>
              <p className="text-sm text-muted-foreground">Không makeup để kết quả tốt nhất</p>
            </div>
          </div>
          
          {/* Buttons */}
          <div className="flex gap-4">
            <button
              onClick={handleSkip}
              className="flex-1 py-4 rounded-full border-2 border-border hover:border-[#c4a882]/30 transition-all"
            >
              Bỏ Qua
            </button>
            <button
              onClick={handleNext}
              className="flex-1 py-4 rounded-full bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white hover:shadow-lg hover:shadow-[#c4a882]/30 transition-all"
            >
              Tiếp Theo
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}