import { useState, useEffect } from 'react';
import { useNavigate, useParams, useLocation } from 'react-router-dom';
import { MapPin, Phone, Clock, CheckCircle } from 'lucide-react';
import { formatDate, formatTime, formatMoney } from '../api';
import { riyadaRepository } from '../repositories/riyadaRepository';
import { useSchedule, useReviewEligibility } from '../hooks/useRiyadaData';
import { joinField, leaveField } from '../lib/socketClient';
import { StarRatingDisplay, StarRatingInput } from '../components/StarRating';
import { useAuth } from '../context/AuthContext';
import { useSmartToast } from '../context/SmartToastContext';
import Header from '../components/Header';
import Button from '../components/Button';
import { ScheduleSkeleton } from '../components/Skeleton';

export default function StadiumDetail() {
  const { id } = useParams();
  const { state } = useLocation();
  const navigate = useNavigate();
  const { session } = useAuth();
  const { success, smartError } = useSmartToast();
  const [stadium, setStadium] = useState(state?.stadium || null);
  const [selected, setSelected] = useState(null);
  const [booking, setBooking] = useState(false);
  const [selecting, setSelecting] = useState(false);
  const [rating, setRating] = useState(0);
  const [submittingReview, setSubmittingReview] = useState(false);
  const fieldId = parseInt(id, 10);

  const { data: scheduleData, isLoading, refetch } = useSchedule(fieldId);
  const { data: reviewInfo, refetch: refetchReview } = useReviewEligibility(fieldId);
  const schedule = scheduleData?.schedule || [];

  useEffect(() => {
    if (!fieldId || !session?.token) return undefined;
    joinField(fieldId);
    return () => leaveField(fieldId);
  }, [fieldId, session?.token]);

  useEffect(() => {
    if (scheduleData && !stadium) {
      setStadium({
        id: scheduleData.id,
        name: scheduleData.name,
        pricePerHour: scheduleData.pricePerHour,
        address: scheduleData.address,
        phone: scheduleData.phone,
        averageRating: scheduleData.averageRating,
        reviewCount: scheduleData.reviewCount,
      });
    }
  }, [scheduleData, stadium]);

  const submitReview = async () => {
    if (rating < 1) return;
    setSubmittingReview(true);
    try {
      await riyadaRepository.submitReview(fieldId, { rating });
      success('شكراً لتقييمك!');
      setRating(0);
      await refetchReview();
      await refetch();
    } catch (err) {
      smartError(err);
    } finally {
      setSubmittingReview(false);
    }
  };

  const slotHours = selected
    ? Math.round((new Date(selected.endTime) - new Date(selected.startTime)) / 3600000)
    : 0;

  const totalPrice = stadium ? stadium.pricePerHour * slotHours : 0;

  const releaseCurrent = async () => {
    if (!selected) return;
    try {
      await riyadaRepository.releaseSlot({
        fieldId,
        startTime: selected.startTime,
        hours: slotHours,
      });
    } catch (_) {
      /* ignore */
    }
  };

  const handleSelectSlot = async (slot) => {
    const hours = Math.round((new Date(slot.endTime) - new Date(slot.startTime)) / 3600000);
    if (selected?.startTime === slot.startTime) {
      await releaseCurrent();
      setSelected(null);
      return;
    }

    setSelecting(true);
    try {
      if (selected) await releaseCurrent();
      await riyadaRepository.selectSlot({ fieldId, startTime: slot.startTime, hours });
      setSelected(slot);
    } catch (err) {
      smartError(err);
      await refetch();
    } finally {
      setSelecting(false);
    }
  };

  const handleBook = async () => {
    if (!selected) return;
    if (!confirm(`تأكيد الحجز؟\n${formatMoney(totalPrice)} — عمولة 2,000 د.ع عند الموافقة`)) return;
    setBooking(true);
    try {
      await riyadaRepository.createBooking({
        userId: session.user.id,
        stadiumId: fieldId,
        startTime: selected.startTime,
        hours: slotHours,
      });
      await releaseCurrent();
      success('تم إرسال طلب الحجز! ستصلك إشعار عند الموافقة');
      navigate('/home', { replace: true });
    } catch (err) {
      smartError(err);
      await refetch();
    } finally {
      setBooking(false);
    }
  };

  useEffect(() => () => {
    if (selected) releaseCurrent();
  }, []);

  if (isLoading && !scheduleData) return <ScheduleSkeleton />;

  return (
    <div className="app-shell min-h-screen pb-8 animate-fade-in">
      <Header title={stadium?.name || 'تفاصيل الملعب'} onBack={() => navigate('/home')} />

      <div className="px-5 -mt-2">
        <div className="card mb-5 gradient-card">
          <div className="flex gap-4 items-center">
            <div className="w-16 h-16 rounded-2xl gradient-hero flex items-center justify-center text-3xl shrink-0">⚽</div>
            <div className="text-right flex-1">
              {stadium?.address && (
                <p className="text-gray-600 text-sm flex items-center gap-1 justify-end"><MapPin className="w-4 h-4" />{stadium.address}</p>
              )}
              {stadium?.phone && (
                <p className="text-gray-600 text-sm flex items-center gap-1 justify-end mt-1"><Phone className="w-4 h-4" />{stadium.phone}</p>
              )}
              <p className="text-brand-600 font-extrabold text-lg mt-2 flex items-center gap-1 justify-end">
                <Clock className="w-5 h-5" />
                {formatMoney(stadium?.pricePerHour)} / ساعة
              </p>
            </div>
          </div>
        </div>

        {(reviewInfo?.reviewCount > 0 || scheduleData?.reviewCount > 0) && (
          <div className="mb-4">
            <StarRatingDisplay
              rating={reviewInfo?.averageRating ?? scheduleData?.averageRating ?? 0}
              reviewCount={reviewInfo?.reviewCount ?? scheduleData?.reviewCount ?? 0}
            />
          </div>
        )}

        <div className="card mb-5">
          <h3 className="font-bold mb-2 text-right">قيّم الملعب</h3>
          {reviewInfo?.userRating ? (
            <div className="text-right">
              <p className="text-sm text-gray-500 mb-1">تقييمك</p>
              <StarRatingDisplay rating={reviewInfo.userRating} />
            </div>
          ) : reviewInfo?.canReview ? (
            <>
              <StarRatingInput value={rating} onChange={setRating} />
              <Button onClick={submitReview} loading={submittingReview} className="mt-2">
                إرسال التقييم
              </Button>
            </>
          ) : (
            <p className="text-sm text-gray-500 text-right">
              {reviewInfo?.hasBooked ? 'لقد قيّمت هذا الملعب' : 'التقييم متاح بعد موافقة المالك على حجزك'}
            </p>
          )}
        </div>

        <h2 className="font-bold text-lg mb-4 text-right">جدول الحجوزات — أسبوع</h2>

        {schedule.map((day, i) => {
          const available = day.slots?.filter((s) => s.isAvailable || s.status === 'available') || [];
          if (available.length === 0 && !day.slots?.some((s) => s.status === 'held')) return null;

          return (
            <div key={i} className="mb-5 animate-slide-up" style={{ animationDelay: `${i * 50}ms` }}>
              <h3 className="font-bold text-brand-600 text-right mb-2 text-sm">
                {formatDate(day.date)}
              </h3>
              <div className="flex flex-wrap gap-2 justify-end">
                {day.slots.map((slot, j) => {
                  const hours = Math.round((new Date(slot.endTime) - new Date(slot.startTime)) / 3600000);
                  const isSelected = selected?.startTime === slot.startTime;
                  const isHeld = slot.status === 'held' && !slot.isAvailable;
                  const isBooked = !slot.isAvailable && !isHeld;

                  if (isBooked) {
                    return (
                      <span key={j} className="slot-booked">
                        {formatTime(slot.startTime)} ({hours}س)
                      </span>
                    );
                  }

                  if (isHeld && !isSelected) {
                    return (
                      <span key={j} className="slot-booked opacity-80">
                        {formatTime(slot.startTime)} — محجوز مؤقتاً
                      </span>
                    );
                  }

                  return (
                    <button
                      key={j}
                      type="button"
                      disabled={selecting}
                      onClick={() => handleSelectSlot(slot)}
                      className={isSelected ? 'slot-selected' : 'slot-available'}
                    >
                      {formatTime(slot.startTime)} ({hours}س)
                    </button>
                  );
                })}
              </div>
            </div>
          );
        })}

        {selected && (
          <div className="card mt-4 border-2 border-brand-200 animate-slide-up sticky bottom-4 shadow-float">
            <div className="flex items-center justify-between mb-3">
              <span className="font-extrabold text-brand-600 text-xl">{formatMoney(totalPrice)}</span>
              <div className="text-right">
                <p className="font-bold">{formatTime(selected.startTime)}</p>
                <p className="text-sm text-gray-500">{slotHours} ساعة</p>
              </div>
            </div>
            <p className="text-xs text-amber-700 bg-amber-50 rounded-lg p-2 mb-3 text-right">
              عمولة 2,000 د.ع تُخصم عند موافقة المالك — الدفع في الملعب
            </p>
            <Button onClick={handleBook} loading={booking}>
              <CheckCircle className="w-5 h-5" /> تأكيد وإرسال الطلب
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}
